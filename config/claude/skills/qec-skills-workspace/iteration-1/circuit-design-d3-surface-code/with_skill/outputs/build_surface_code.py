"""Build a d=3 rotated surface code memory-Z circuit from scratch.

Constructs the circuit manually (no stim.Circuit.generated), adds uniform
depolarizing noise at p=0.001, and verifies the fault distance equals 3.

Run with:
    uv run --with stim,pymatching python build_surface_code.py
"""

import sys
from pathlib import Path

import stim

# ==============================================================================
# Noise model (embedded from the skill's noise_model.py for standalone use)
# ==============================================================================

from collections import Counter, defaultdict

CLIFFORD_1Q = "C1"
CLIFFORD_2Q = "C2"
ANNOTATION = "info"
MPP_TYPE = "MPP"
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
    "MPP": MPP_TYPE,
    "MR": MEASURE_RESET_1Q, "MRX": MEASURE_RESET_1Q, "MRY": MEASURE_RESET_1Q,
    "MRZ": MEASURE_RESET_1Q,
    "M": JUST_MEASURE_1Q, "MX": JUST_MEASURE_1Q, "MY": JUST_MEASURE_1Q,
    "MZ": JUST_MEASURE_1Q,
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
    if t in {JUST_RESET_1Q, JUST_MEASURE_1Q, MPP_TYPE, MEASURE_RESET_1Q}
}


class NoiseRule:
    def __init__(self, *, after, flip_result=0):
        self.after = after
        self.flip_result = flip_result

    def _append_noisy_version_of(self, *, split_op, out_during_moment,
                                  after_moments, immune_qubits):
        targets = split_op.targets_copy()
        if immune_qubits and any(
            (t.is_qubit_target or t.is_x_target or t.is_y_target or t.is_z_target)
            and t.value in immune_qubits for t in targets
        ):
            out_during_moment.append(split_op)
            return
        args = split_op.gate_args_copy()
        if self.flip_result:
            args = [self.flip_result]
        out_during_moment.append(split_op.name, targets, args)
        raw_targets = [t.value for t in targets if not t.is_combiner]
        for op_name, arg in self.after.items():
            after_moments[(op_name, arg)].append(op_name, raw_targets, arg)


class NoiseModel:
    def __init__(self, idle_depolarization, additional_depolarization_waiting_for_m_or_r=0,
                 gate_rules=None, measure_rules=None,
                 any_clifford_1q_rule=None, any_clifford_2q_rule=None):
        self.idle_depolarization = idle_depolarization
        self.additional_depolarization_waiting_for_m_or_r = additional_depolarization_waiting_for_m_or_r
        self.gate_rules = gate_rules
        self.measure_rules = measure_rules
        self.any_clifford_1q_rule = any_clifford_1q_rule
        self.any_clifford_2q_rule = any_clifford_2q_rule

    @staticmethod
    def uniform_depolarizing(p):
        return NoiseModel(
            idle_depolarization=p,
            any_clifford_1q_rule=NoiseRule(after={"DEPOLARIZE1": p}),
            any_clifford_2q_rule=NoiseRule(after={"DEPOLARIZE2": p}),
            measure_rules={
                "X": NoiseRule(after={}, flip_result=p),
                "Y": NoiseRule(after={}, flip_result=p),
                "Z": NoiseRule(after={}, flip_result=p),
            },
            gate_rules={
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
        if self.measure_rules is not None and t in (MPP_TYPE, JUST_MEASURE_1Q):
            measure_basis = _measure_basis(split_op=split_op)
            if measure_basis is not None:
                rule = self.measure_rules.get(measure_basis)
                if rule is not None:
                    return rule
        if self.gate_rules is not None and t == MEASURE_RESET_1Q:
            # MR = measure + reset; apply reset rule if available
            base_name = split_op.name.replace("MR", "R") if split_op.name.startswith("MR") else None
            if base_name and base_name in self.gate_rules:
                return self.gate_rules[base_name]
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
        collapse_set = set(collapse_qubits)
        clifford_set = set(clifford_qubits)
        idle = sorted(system_qubits - collapse_set - clifford_set - immune_qubits)
        if idle and self.idle_depolarization:
            out.append("DEPOLARIZE1", idle, self.idle_depolarization)

    def _append_noisy_moment(self, *, moment_split_ops, out, system_qubits, immune_qubits):
        after = defaultdict(stim.Circuit)
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

    def noisy_circuit(self, circuit, *, system_qubits=None, immune_qubits=None):
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
    elif t == MPP_TYPE:
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


# ==============================================================================
# d=3 Rotated Surface Code: Qubit Layout
# ==============================================================================
#
# The d=3 rotated surface code has 9 data qubits and 8 ancilla qubits (4 X-type
# stabilizers and 4 Z-type stabilizers), for 17 qubits total.
#
# We use a coordinate system where data qubits sit on integer lattice points
# and ancilla qubits sit at half-integer positions. The rotated layout tiles
# the plane at 45 degrees, so data qubits have coordinates (i, j) with
# i + j even.
#
# Layout (coordinates shown):
#
#     (0,0)  data     (1,0)  X-anc    (2,0)  data     (3,0)  Z-anc    (4,0) data
#     (0,1)  Z-anc    (1,1)  data     (2,1)  X-anc    (3,1)  data     (4,1) Z-anc (boundary)
#     (0,2)  data     (1,2)  X-anc(b) (2,2)  data     (3,2)  Z-anc    (4,2) data
#     (0,3)  X-anc(b) (1,3)  data     (2,3)  X-anc    (3,3)  data     (4,3) ...
#     (0,4)  data     (1,4)  ...      (2,4)  data     ...
#
# For d=3 rotated, the standard coordinate assignment is:
#
#   Data qubits at positions (in a 5x5 grid with i+j even):
#     (1,1), (3,1), (0,2), (2,2), (4,2), (1,3), (3,3), (0,4), (2,4)
#     -- but let's use the more standard stim convention.
#
# We'll follow the rotated surface code convention used in stim:
# - Qubits on a grid of size (2d-1) x (2d-1) = 5x5
# - Data qubits at (x, y) where x + y is even, and both in range [0, 2d-2]
# - X-ancillas at (x, y) where x is even, y is odd
# - Z-ancillas at (x, y) where x is odd, y is even
# - Boundary conditions: some ancillas are weight-2 (on the boundary)

def build_d3_rotated_surface_code(num_rounds: int = 3) -> stim.Circuit:
    """Build a d=3 rotated surface code memory-Z experiment from scratch.

    Returns the noiseless circuit with detectors and observables.
    """
    d = 3
    grid_size = 2 * d - 1  # 5

    # -------------------------------------------------------------------------
    # Identify data qubits, X-ancillas, and Z-ancillas by grid coordinate.
    # -------------------------------------------------------------------------

    data_coords = []
    x_anc_coords = []
    z_anc_coords = []

    for y in range(grid_size):
        for x in range(grid_size):
            if x % 2 == 0 and y % 2 == 0:
                # Data qubit
                data_coords.append((x, y))
            elif x % 2 == 1 and y % 2 == 1:
                # X-type stabilizer ancilla (center of X plaquette)
                x_anc_coords.append((x, y))
            elif x % 2 == 0 and y % 2 == 1:
                # Z-type stabilizer ancilla (for rotated surface code)
                # Actually, for the standard rotated surface code, ancillas at
                # even-x, odd-y are one type and odd-x, even-y are the other.
                # Let's be careful: in the rotated code, X stabilizers measure
                # X on their neighboring data qubits, and Z stabilizers measure Z.
                #
                # Convention: (even x, odd y) -> Z-type ancilla
                z_anc_coords.append((x, y))
            elif x % 2 == 1 and y % 2 == 0:
                # (odd x, even y) -> X-type ancilla
                x_anc_coords.append((x, y))

    # Filter to only include ancillas that are inside the rotated diamond.
    # For a d=3 rotated code on a 5x5 grid, the boundary is defined by which
    # ancillas have at least 2 data-qubit neighbors within the grid.
    def data_neighbors(ax, ay):
        """Return grid coordinates of data qubits adjacent to ancilla (ax, ay)."""
        nbrs = []
        for dx, dy in [(-1, -1), (1, -1), (-1, 1), (1, 1)]:
            nx, ny = ax + dx, ay + dy
            if 0 <= nx < grid_size and 0 <= ny < grid_size:
                nbrs.append((nx, ny))
        return nbrs

    data_set = set(data_coords)
    x_anc_coords = [c for c in x_anc_coords if len([n for n in data_neighbors(*c) if n in data_set]) >= 2]
    z_anc_coords = [c for c in z_anc_coords if len([n for n in data_neighbors(*c) if n in data_set]) >= 2]

    all_coords = data_coords + x_anc_coords + z_anc_coords
    # Sort for deterministic qubit index assignment: by y then x.
    all_coords.sort(key=lambda c: (c[1], c[0]))

    coord_to_idx = {c: i for i, c in enumerate(all_coords)}

    data_qubits = sorted(coord_to_idx[c] for c in data_coords)
    x_ancillas = sorted(coord_to_idx[c] for c in x_anc_coords)
    z_ancillas = sorted(coord_to_idx[c] for c in z_anc_coords)
    all_ancillas = sorted(x_ancillas + z_ancillas)
    num_ancillas = len(all_ancillas)

    # -------------------------------------------------------------------------
    # Build the CX gate schedule.
    #
    # For each ancilla, we need to apply CX gates to its neighboring data qubits
    # in a specific order. The order must be consistent to avoid hook errors.
    #
    # Standard 4-step CX schedule for rotated surface code:
    #   Step 0: ancilla <-> data at relative position (-1, -1)  [top-left]
    #   Step 1: ancilla <-> data at relative position (+1, -1)  [top-right]
    #   Step 2: ancilla <-> data at relative position (-1, +1)  [bottom-left]
    #   Step 3: ancilla <-> data at relative position (+1, +1)  [bottom-right]
    #
    # For Z-stabilizers: CX with ancilla as target (data -> ancilla)
    # For X-stabilizers: CX with ancilla as control (ancilla -> data)
    # -------------------------------------------------------------------------

    # The relative positions of data qubits around each ancilla, in CX order.
    cx_order = [(-1, -1), (+1, -1), (-1, +1), (+1, +1)]

    cx_layers = [[] for _ in range(4)]  # 4 layers of CX gates

    for ac in x_anc_coords:
        ax, ay = ac
        a_idx = coord_to_idx[ac]
        for step, (dx, dy) in enumerate(cx_order):
            dc = (ax + dx, ay + dy)
            if dc in data_set:
                d_idx = coord_to_idx[dc]
                # X-stabilizer: ancilla is control
                cx_layers[step].append((a_idx, d_idx))

    for ac in z_anc_coords:
        ax, ay = ac
        a_idx = coord_to_idx[ac]
        for step, (dx, dy) in enumerate(cx_order):
            dc = (ax + dx, ay + dy)
            if dc in data_set:
                d_idx = coord_to_idx[dc]
                # Z-stabilizer: ancilla is target
                cx_layers[step].append((d_idx, a_idx))

    # -------------------------------------------------------------------------
    # Map ancilla index -> its sorted position in measurement order.
    # Ancillas are measured in index order, so measurement k corresponds to
    # all_ancillas[k].
    # -------------------------------------------------------------------------
    anc_measure_order = {a: i for i, a in enumerate(all_ancillas)}

    # -------------------------------------------------------------------------
    # Build the circuit.
    # -------------------------------------------------------------------------

    circuit = stim.Circuit()

    # Assign qubit coordinates for visualization.
    for coord, idx in sorted(coord_to_idx.items(), key=lambda x: x[1]):
        circuit.append("QUBIT_COORDS", [idx], [coord[0], coord[1]])

    # -------------------------------------------------------------------------
    # Initialization: reset all qubits, then prepare X-ancillas in |+> state.
    # -------------------------------------------------------------------------
    circuit.append("R", data_qubits + all_ancillas)
    circuit.append("TICK")

    # X-ancillas need to be in the X basis for X-stabilizer measurement.
    circuit.append("H", x_ancillas)
    circuit.append("TICK")

    # -------------------------------------------------------------------------
    # Syndrome extraction rounds
    # -------------------------------------------------------------------------

    for rnd in range(num_rounds):
        # 4 CX layers
        for layer in cx_layers:
            pairs = []
            for ctrl, tgt in layer:
                pairs.extend([ctrl, tgt])
            if pairs:
                circuit.append("CX", pairs)
            circuit.append("TICK")

        # Return X-ancillas to Z basis before measurement.
        circuit.append("H", x_ancillas)
        circuit.append("TICK")

        # Measure and reset all ancillas.
        circuit.append("MR", all_ancillas)

        # -----------------------------------------------------------------
        # Detectors: each ancilla's measurement is compared to the previous
        # round's measurement of the same ancilla (or to the initial reset
        # for round 0).
        # -----------------------------------------------------------------
        for anc_idx in all_ancillas:
            k = anc_measure_order[anc_idx]
            ac = all_coords[anc_idx]

            if rnd == 0:
                # First round: the ancilla was freshly reset, so the expected
                # measurement is 0. The detector is just the current result.
                circuit.append(
                    "DETECTOR",
                    [stim.target_rec(k - num_ancillas)],  # current measurement
                    [ac[0], ac[1], 0],
                )
            else:
                # Subsequent rounds: compare current to previous round.
                circuit.append(
                    "DETECTOR",
                    [
                        stim.target_rec(k - num_ancillas),           # current
                        stim.target_rec(k - num_ancillas - num_ancillas),  # previous
                    ],
                    [ac[0], ac[1], rnd],
                )

        circuit.append("SHIFT_COORDS", [], [0, 0, 1])
        circuit.append("TICK")

        # Re-prepare X-ancillas for the next round (unless this is the last round).
        if rnd < num_rounds - 1:
            circuit.append("H", x_ancillas)
            circuit.append("TICK")

    # -------------------------------------------------------------------------
    # Termination: measure all data qubits in the Z basis.
    # -------------------------------------------------------------------------
    circuit.append("M", data_qubits)

    # Final-round detectors: for each Z-stabilizer, compare the product of
    # the data-qubit measurements in that stabilizer's support to the last
    # syndrome measurement of that ancilla.
    num_data = len(data_qubits)
    data_qubit_set = set(data_qubits)
    data_measure_offset = {d: i for i, d in enumerate(data_qubits)}

    for ac in z_anc_coords:
        ax, ay = ac
        a_idx = coord_to_idx[ac]
        k = anc_measure_order[a_idx]

        # Data qubits in this Z-stabilizer's support
        support_data = []
        for dx, dy in [(-1, -1), (1, -1), (-1, 1), (1, 1)]:
            dc = (ax + dx, ay + dy)
            if dc in data_set:
                d_idx = coord_to_idx[dc]
                support_data.append(d_idx)

        rec_targets = []
        # The last ancilla measurement for this stabilizer
        rec_targets.append(stim.target_rec(-(num_data + num_ancillas) + k))
        # The data qubit measurements
        for d_idx in support_data:
            dm_offset = data_measure_offset[d_idx]
            rec_targets.append(stim.target_rec(dm_offset - num_data))

        circuit.append("DETECTOR", rec_targets, [ac[0], ac[1], num_rounds])

    # For X-stabilizers, final detectors compare to last X syndrome measurement.
    for ac in x_anc_coords:
        ax, ay = ac
        a_idx = coord_to_idx[ac]
        k = anc_measure_order[a_idx]

        support_data = []
        for dx, dy in [(-1, -1), (1, -1), (-1, 1), (1, 1)]:
            dc = (ax + dx, ay + dy)
            if dc in data_set:
                d_idx = coord_to_idx[dc]
                support_data.append(d_idx)

        rec_targets = []
        # Last ancilla measurement for this X-stabilizer
        rec_targets.append(stim.target_rec(-(num_data + num_ancillas) + k))
        # X-stabilizer data qubit measurements in X basis -- but wait, we
        # measure data qubits in Z. X-stabilizer detectors at the final round
        # only work if we're doing a memory-X experiment. For memory-Z, the
        # final detectors for X stabilizers come from comparing the last two
        # rounds of X-syndrome, which we already handled above.
        #
        # So we should NOT add final-round detectors for X-stabilizers in a
        # memory-Z experiment. The X-stabilizer detectors are fully covered
        # by the round-to-round comparisons.

        # Intentionally omitted: no final X-stabilizer detectors for memory-Z.
        pass

    # -------------------------------------------------------------------------
    # Observable: logical Z operator is a column of Z on data qubits.
    # For the d=3 rotated code, the logical Z is a vertical chain of data
    # qubits along the left boundary: x=0 column.
    # -------------------------------------------------------------------------
    for dc in data_coords:
        if dc[0] == 0:
            d_idx = coord_to_idx[dc]
            dm_offset = data_measure_offset[d_idx]
            circuit.append(
                "OBSERVABLE_INCLUDE",
                [stim.target_rec(dm_offset - num_data)],
                0,
            )

    return circuit


# ==============================================================================
# Main: build, add noise, verify
# ==============================================================================

def main():
    print("Building d=3 rotated surface code circuit (3 rounds)...")
    noiseless = build_d3_rotated_surface_code(num_rounds=3)

    # ---- Circuit stats ----
    print(f"\nCircuit stats:")
    print(f"  num_qubits:      {noiseless.num_qubits}")
    print(f"  num_detectors:   {noiseless.num_detectors}")
    print(f"  num_observables: {noiseless.num_observables}")

    # ---- Insert noise ----
    p = 0.001
    model = NoiseModel.uniform_depolarizing(p)
    noisy = model.noisy_circuit(noiseless)

    # ---- Build DEM ----
    try:
        dem = noisy.detector_error_model(decompose_errors=True)
        print(f"\nDEM built successfully: {dem.num_detectors} detectors, "
              f"{dem.num_errors} errors")
    except Exception as e:
        print(f"\nERROR building DEM: {e}")
        print("\nDumping noiseless circuit for debugging:")
        print(noiseless)
        sys.exit(1)

    # ---- Check for missing detectors ----
    # (Detectors that no error can trigger, which usually indicates a wiring bug)

    # ---- Verify fault distance ----
    print("\nChecking fault distance...")
    try:
        logical_errors = noisy.shortest_graphlike_error(
            ignore_ungraphlike_errors=False,
            canonicalize_circuit_errors=True,
        )
        fault_distance = len(logical_errors)
        print(f"  Fault distance: {fault_distance}")
        if fault_distance == 3:
            print("  PASS: fault distance matches d=3")
        else:
            print(f"  FAIL: expected fault distance 3, got {fault_distance}")
            for i, err in enumerate(logical_errors):
                print(f"    Error {i}: {err}")
    except Exception as e:
        print(f"  ERROR: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
