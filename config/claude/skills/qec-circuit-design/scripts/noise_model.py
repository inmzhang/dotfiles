"""Noise model utilities for inserting noise into stim circuits.

Adapted from Craig Gidney's code (CC BY 4.0), originally from:
    Gidney, C. (2022). Data for "Inplace Access to the Surface Code Y Basis".
    https://doi.org/10.5281/zenodo.7487893

Also adapted from https://github.com/tqec/tqec/blob/main/src/tqec/utils/noise_model.py.

Usage:
    from noise_model import NoiseModel

    model = NoiseModel.uniform_depolarizing(p=0.001)
    noisy = model.noisy_circuit(noiseless_circuit)

    # Or superconducting-inspired noise:
    model = NoiseModel.si1000(p=0.001)
    noisy = model.noisy_circuit(noiseless_circuit)
"""

from collections import Counter, defaultdict
from collections.abc import Iterator, Set

import stim

# ==============================================================================
# Operation type classification
# ==============================================================================

CLIFFORD_1Q = "C1"
CLIFFORD_2Q = "C2"
ANNOTATION = "info"
MPP = "MPP"
MEASURE_RESET_1Q = "MR1"
JUST_MEASURE_1Q = "M1"
JUST_RESET_1Q = "R1"
NOISE = "!?"

OP_TYPES = {
    "I": CLIFFORD_1Q,
    "X": CLIFFORD_1Q, "Y": CLIFFORD_1Q, "Z": CLIFFORD_1Q,
    "C_XYZ": CLIFFORD_1Q, "C_ZYX": CLIFFORD_1Q,
    "H": CLIFFORD_1Q, "H_XY": CLIFFORD_1Q, "H_XZ": CLIFFORD_1Q, "H_YZ": CLIFFORD_1Q,
    "S": CLIFFORD_1Q, "S_DAG": CLIFFORD_1Q,
    "SQRT_X": CLIFFORD_1Q, "SQRT_X_DAG": CLIFFORD_1Q,
    "SQRT_Y": CLIFFORD_1Q, "SQRT_Y_DAG": CLIFFORD_1Q,
    "SQRT_Z": CLIFFORD_1Q, "SQRT_Z_DAG": CLIFFORD_1Q,
    "CNOT": CLIFFORD_2Q, "CX": CLIFFORD_2Q, "CY": CLIFFORD_2Q, "CZ": CLIFFORD_2Q,
    "ISWAP": CLIFFORD_2Q, "ISWAP_DAG": CLIFFORD_2Q,
    "SQRT_XX": CLIFFORD_2Q, "SQRT_XX_DAG": CLIFFORD_2Q,
    "SQRT_YY": CLIFFORD_2Q, "SQRT_YY_DAG": CLIFFORD_2Q,
    "SQRT_ZZ": CLIFFORD_2Q, "SQRT_ZZ_DAG": CLIFFORD_2Q,
    "SWAP": CLIFFORD_2Q,
    "XCX": CLIFFORD_2Q, "XCY": CLIFFORD_2Q, "XCZ": CLIFFORD_2Q,
    "YCX": CLIFFORD_2Q, "YCY": CLIFFORD_2Q, "YCZ": CLIFFORD_2Q,
    "ZCX": CLIFFORD_2Q, "ZCY": CLIFFORD_2Q, "ZCZ": CLIFFORD_2Q,
    "MPP": MPP,
    "MR": MEASURE_RESET_1Q, "MRX": MEASURE_RESET_1Q, "MRY": MEASURE_RESET_1Q, "MRZ": MEASURE_RESET_1Q,
    "M": JUST_MEASURE_1Q, "MX": JUST_MEASURE_1Q, "MY": JUST_MEASURE_1Q, "MZ": JUST_MEASURE_1Q,
    "R": JUST_RESET_1Q, "RX": JUST_RESET_1Q, "RY": JUST_RESET_1Q, "RZ": JUST_RESET_1Q,
    "DETECTOR": ANNOTATION, "OBSERVABLE_INCLUDE": ANNOTATION,
    "QUBIT_COORDS": ANNOTATION, "SHIFT_COORDS": ANNOTATION,
    "TICK": ANNOTATION, "E": ANNOTATION,
    "DEPOLARIZE1": NOISE, "DEPOLARIZE2": NOISE,
    "PAULI_CHANNEL_1": NOISE, "PAULI_CHANNEL_2": NOISE,
    "X_ERROR": NOISE, "Y_ERROR": NOISE, "Z_ERROR": NOISE,
}
OP_MEASURE_BASES = {"M": "Z", "MX": "X", "MY": "Y", "MZ": "Z", "MPP": ""}
COLLAPSING_OPS = {
    op for op, t in OP_TYPES.items()
    if t in {JUST_RESET_1Q, JUST_MEASURE_1Q, MPP, MEASURE_RESET_1Q}
}


class NoiseRule:
    """Describes how to add noise to an operation."""

    def __init__(self, *, after: dict[str, float], flip_result: float = 0):
        if not (0 <= flip_result <= 1):
            raise ValueError(f"not (0 <= {flip_result=} <= 1)")
        for k, p in after.items():
            if OP_TYPES[k] != NOISE:
                raise ValueError(f"not a noise channel: {k} from {after=}")
            if not (0 <= p <= 1):
                raise ValueError(f"not (0 <= {p} <= 1) from {after=}")
        self.after = after
        self.flip_result = flip_result

    def _append_noisy_version_of(
        self, *, split_op: stim.CircuitInstruction,
        out_during_moment: stim.Circuit,
        after_moments: defaultdict[tuple[str, float], stim.Circuit],
        immune_qubits: Set[int],
    ) -> None:
        targets = split_op.targets_copy()
        if immune_qubits and any(
            (t.is_qubit_target or t.is_x_target or t.is_y_target or t.is_z_target)
            and t.value in immune_qubits for t in targets
        ):
            out_during_moment.append(split_op)
            return
        args = split_op.gate_args_copy()
        if self.flip_result:
            t = OP_TYPES[split_op.name]
            assert t in {MPP, JUST_MEASURE_1Q, MEASURE_RESET_1Q}
            assert len(args) == 0
            args = [self.flip_result]
        out_during_moment.append(split_op.name, targets, args)
        raw_targets = [t.value for t in targets if not t.is_combiner]
        for op_name, arg in self.after.items():
            after_moments[(op_name, arg)].append(op_name, raw_targets, arg)


class NoiseModel:
    """Noise model that can be applied to a stim.Circuit."""

    def __init__(
        self, idle_depolarization: float,
        additional_depolarization_waiting_for_m_or_r: float = 0,
        gate_rules: dict[str, NoiseRule] | None = None,
        measure_rules: dict[str, NoiseRule] | None = None,
        any_clifford_1q_rule: NoiseRule | None = None,
        any_clifford_2q_rule: NoiseRule | None = None,
    ):
        self.idle_depolarization = idle_depolarization
        self.additional_depolarization_waiting_for_m_or_r = additional_depolarization_waiting_for_m_or_r
        self.gate_rules = gate_rules
        self.measure_rules = measure_rules
        self.any_clifford_1q_rule = any_clifford_1q_rule
        self.any_clifford_2q_rule = any_clifford_2q_rule

    @staticmethod
    def si1000(p: float) -> "NoiseModel":
        """Superconducting-inspired noise model from 'A Fault-Tolerant Honeycomb Memory'."""
        return NoiseModel(
            idle_depolarization=p / 10,
            additional_depolarization_waiting_for_m_or_r=2 * p,
            any_clifford_1q_rule=NoiseRule(after={"DEPOLARIZE1": p / 10}),
            any_clifford_2q_rule=NoiseRule(after={"DEPOLARIZE2": p}),
            measure_rules={"Z": NoiseRule(after={}, flip_result=p * 5)},
            gate_rules={"R": NoiseRule(after={"X_ERROR": p * 2})},
        )

    @staticmethod
    def uniform_depolarizing(p: float) -> "NoiseModel":
        """Uniform depolarizing noise: parameter p applied to all operations equally."""
        return NoiseModel(
            idle_depolarization=p,
            any_clifford_1q_rule=NoiseRule(after={"DEPOLARIZE1": p}),
            any_clifford_2q_rule=NoiseRule(after={"DEPOLARIZE2": p}),
            measure_rules={
                "X": NoiseRule(after={}, flip_result=p),
                "Y": NoiseRule(after={}, flip_result=p),
                "Z": NoiseRule(after={}, flip_result=p),
                "XX": NoiseRule(after={}, flip_result=p),
                "YY": NoiseRule(after={}, flip_result=p),
                "ZZ": NoiseRule(after={}, flip_result=p),
            },
            gate_rules={
                "RX": NoiseRule(after={"Z_ERROR": p}),
                "RY": NoiseRule(after={"X_ERROR": p}),
                "R": NoiseRule(after={"X_ERROR": p}),
            },
        )

    def _noise_rule_for_split_operation(self, *, split_op):
        if _occurs_in_classical_control_system(split_op):
            return None
        if self.gate_rules is not None:
            rule = self.gate_rules.get(split_op.name)
            if rule is not None:
                return rule
        t = OP_TYPES[split_op.name]
        if self.any_clifford_1q_rule is not None and t == CLIFFORD_1Q:
            return self.any_clifford_1q_rule
        if self.any_clifford_2q_rule is not None and t == CLIFFORD_2Q:
            return self.any_clifford_2q_rule
        if self.measure_rules is not None and t in (MPP, JUST_MEASURE_1Q):
            measure_basis = _measure_basis(split_op=split_op)
            assert measure_basis is not None
            rule = self.measure_rules.get(measure_basis)
            if rule is not None:
                return rule
        raise ValueError(f"No noise specified for {split_op=}.")

    def _append_idle_error(self, *, moment_split_ops, out, system_qubits, immune_qubits):
        collapse_qubits, clifford_qubits = [], []
        for split_op in moment_split_ops:
            if _occurs_in_classical_control_system(split_op):
                continue
            qubits_out = collapse_qubits if split_op.name in COLLAPSING_OPS else clifford_qubits
            for target in split_op.targets_copy():
                if not target.is_combiner:
                    qubits_out.append(target.value)
        usage_counts = Counter(collapse_qubits + clifford_qubits)
        multi = {q for q, c in usage_counts.items() if c != 1}
        if multi:
            raise ValueError(f"Qubits operated on multiple times without TICK: {sorted(multi)}")
        collapse_set = set(collapse_qubits)
        clifford_set = set(clifford_qubits)
        idle = sorted(system_qubits - collapse_set - clifford_set - immune_qubits)
        if idle and self.idle_depolarization:
            out.append("DEPOLARIZE1", idle, self.idle_depolarization)
        waiting = sorted(system_qubits - collapse_set - immune_qubits)
        if collapse_set and waiting and self.additional_depolarization_waiting_for_m_or_r:
            out.append("DEPOLARIZE1", idle, self.additional_depolarization_waiting_for_m_or_r)

    def _append_noisy_moment(self, *, moment_split_ops, out, system_qubits, immune_qubits):
        after: defaultdict[tuple[str, float], stim.Circuit] = defaultdict(stim.Circuit)
        for split_op in moment_split_ops:
            rule = self._noise_rule_for_split_operation(split_op=split_op)
            if rule is None:
                out.append(split_op)
            else:
                rule._append_noisy_version_of(
                    split_op=split_op, out_during_moment=out,
                    after_moments=after, immune_qubits=immune_qubits,
                )
        for k in sorted(after.keys()):
            out += after[k]
        self._append_idle_error(
            moment_split_ops=moment_split_ops, out=out,
            system_qubits=system_qubits, immune_qubits=immune_qubits,
        )

    def noisy_circuit(
        self, circuit: stim.Circuit, *,
        system_qubits: set[int] | None = None,
        immune_qubits: set[int] | None = None,
    ) -> stim.Circuit:
        """Return a noisy version of the circuit."""
        if system_qubits is None:
            system_qubits = set(range(circuit.num_qubits))
        if immune_qubits is None:
            immune_qubits = set()
        result = stim.Circuit()
        for moment in _iter_split_op_moments(circuit, immune_qubits=immune_qubits):
            if not result:
                pass
            elif isinstance(moment, stim.CircuitRepeatBlock):
                pass
            elif isinstance(result[-1], stim.CircuitRepeatBlock):
                pass
            else:
                result.append("TICK", [], [])
            if isinstance(moment, stim.CircuitRepeatBlock):
                noisy_body = self.noisy_circuit(
                    moment.body_copy(), system_qubits=system_qubits, immune_qubits=immune_qubits,
                )
                result.append(stim.CircuitRepeatBlock(repeat_count=moment.repeat_count, body=noisy_body))
            else:
                self._append_noisy_moment(
                    moment_split_ops=moment, out=result,
                    system_qubits=system_qubits, immune_qubits=immune_qubits,
                )
        return result


# ==============================================================================
# Internal helpers
# ==============================================================================

def _occurs_in_classical_control_system(op):
    t = OP_TYPES[op.name]
    if t == ANNOTATION:
        return True
    if t == CLIFFORD_2Q:
        targets = op.targets_copy()
        for k in range(0, len(targets), 2):
            a, b = targets[k], targets[k + 1]
            if not (a.is_measurement_record_target or a.is_sweep_bit_target
                    or b.is_measurement_record_target or b.is_sweep_bit_target):
                return False
        return True
    return False


def _split_targets_if_needed(op, immune_qubits):
    t = OP_TYPES[op.name]
    if t == CLIFFORD_2Q:
        targets = op.targets_copy()
        if immune_qubits or any(t.is_measurement_record_target for t in targets):
            args = op.gate_args_copy()
            for k in range(0, len(targets), 2):
                yield stim.CircuitInstruction(op.name, targets[k:k+2], args)
        else:
            yield op
    elif t == MPP:
        targets = op.targets_copy()
        args = op.gate_args_copy()
        k, start = 0, 0
        while k < len(targets):
            if k + 1 == len(targets) or not targets[k + 1].is_combiner:
                yield stim.CircuitInstruction(op.name, targets[start:k+1], args)
                k += 1
                start = k
            else:
                k += 2
    elif t in [NOISE, ANNOTATION]:
        yield op
    else:
        if immune_qubits:
            args = op.gate_args_copy()
            for t_item in op.targets_copy():
                yield stim.CircuitInstruction(op.name, [t_item], args)
        else:
            yield op


def _iter_split_op_moments(circuit, *, immune_qubits):
    cur_moment = []
    for op in circuit:
        if isinstance(op, stim.CircuitRepeatBlock):
            if cur_moment:
                yield cur_moment
                cur_moment = []
            yield op
        elif op.name == "TICK":
            yield cur_moment
            cur_moment = []
        else:
            cur_moment.extend(_split_targets_if_needed(op, immune_qubits=immune_qubits))
    if cur_moment:
        yield cur_moment


def _measure_basis(*, split_op):
    result = OP_MEASURE_BASES.get(split_op.name)
    if result == "":
        targets = split_op.targets_copy()
        for k in range(0, len(targets), 2):
            t = targets[k]
            if t.is_x_target:
                result += "X"
            elif t.is_y_target:
                result += "Y"
            elif t.is_z_target:
                result += "Z"
            else:
                raise NotImplementedError(f"{targets=}")
    return result
