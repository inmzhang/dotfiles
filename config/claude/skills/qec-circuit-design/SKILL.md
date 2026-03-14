---
name: qec-circuit-design
description: >
  Design, build, and verify quantum error correction circuits using stim.
  Use this skill when the user wants to construct QEC circuits (surface code,
  color code, repetition code, QLDPC, etc.), add detectors and observables,
  verify stabilizer flows, insert noise models, build detector error models,
  check fault distance, or debug circuit correctness issues. Also use when
  the user mentions syndrome extraction circuits, logical gate circuits,
  magic state preparation, stabilizer flows, detection regions, or chunk-based
  circuit construction.
---

# QEC Circuit Design with Stim

This skill guides the construction and verification of quantum error correction
circuits using the `stim` Python library. It covers the full lifecycle from
building noiseless circuits through flow verification and fault distance checking.

## Environment Setup

All scripts use `uv` for dependency management. Before running any Python code:

```bash
# For scripts in this skill's scripts/ directory:
uv run --with stim scripts/noise_model.py  # example

# For user scripts:
uv run --with stim python my_script.py

# If pymatching is also needed (for distance verification):
uv run --with stim,pymatching python my_script.py
```

The bundled `scripts/noise_model.py` provides `NoiseModel.uniform_depolarizing(p)`
and `NoiseModel.si1000(p)` for inserting noise into noiseless circuits. Copy it
into the user's project when they need noise insertion.

## Circuit Construction

### From Stim DSL

```python
import stim

circuit = stim.Circuit("""
    QUBIT_COORDS(0, 0) 0
    QUBIT_COORDS(1, 0) 1
    QUBIT_COORDS(0.5, 0.5) 2
    R 0 1 2
    TICK
    CX 0 2
    TICK
    CX 1 2
    TICK
    MR 2
    DETECTOR(0.5, 0.5, 0) rec[-1]
""")
```

### Programmatic Construction

```python
circuit = stim.Circuit()
# Assign coordinates for visualization
for i, (x, y) in enumerate(qubit_positions):
    circuit.append("QUBIT_COORDS", [i], [x, y])

circuit.append("R", data_qubits + ancilla_qubits)
circuit.append("TICK")

# Build CX layers for stabilizer measurement
for control, target in cx_pairs_layer1:
    circuit.append("CX", [control, target])
circuit.append("TICK")

# Measure ancillas
circuit.append("MR", ancilla_qubits)
```

### Repetition with REPEAT Blocks

```python
# Build one round as a sub-circuit
round_body = stim.Circuit()
# ... add gates, measurements, detectors ...
round_body.append("SHIFT_COORDS", [], [0, 0, 1])  # advance time coordinate

# Wrap in REPEAT for multiple rounds
circuit.append(stim.CircuitRepeatBlock(repeat_count=num_rounds - 1, body=round_body))
```

### Pre-built Standard Circuits

```python
circuit = stim.Circuit.generated(
    code_task="surface_code:rotated_memory_z",  # or rotated_memory_x, color_code:memory_xyz, etc.
    distance=5,
    rounds=10,
    after_clifford_depolarization=0.001,
)
```

Available code_tasks: `repetition_code:memory`, `surface_code:rotated_memory_x`,
`surface_code:rotated_memory_z`, `surface_code:unrotated_memory_x`,
`surface_code:unrotated_memory_z`, `color_code:memory_xyz`.

## Detectors and Observables

### Detector Declaration

A DETECTOR is a parity of measurement results that is deterministic under
noiseless execution. When noise flips the parity, the detector "fires."

```python
# Compare current and previous round measurements of the same stabilizer
circuit.append("DETECTOR", [
    stim.target_rec(-1),   # current round measurement
    stim.target_rec(-num_ancillas - 1),  # same ancilla's previous measurement
], [x_coord, y_coord, t_coord])  # spatial+temporal coordinates
```

For the **first round**, detectors compare against the initial reset state
(no previous measurement to compare against), so they reference only one `rec`.

### Observable Declaration

An OBSERVABLE_INCLUDE marks which measurements contribute to a logical
observable. Stim tracks how errors flip observables to compute logical error rates.

```python
# Final data qubit measurements that form the logical observable
circuit.append("OBSERVABLE_INCLUDE", [stim.target_rec(-1)], 0)  # observable index 0
```

### Multi-Qubit Pauli Product Measurement (MPP)

MPP is the native instruction for measuring arbitrary stabilizer products:

```python
circuit.append("MPP", [
    stim.target_x(0), stim.target_combiner(),
    stim.target_x(1), stim.target_combiner(),
    stim.target_x(2), stim.target_combiner(),
    stim.target_x(3),
])
# Measures X0*X1*X2*X3, produces one measurement result
```

## Stabilizer Flow Verification

Flows formalize how stabilizers propagate through a circuit chunk.

### Verifying Individual Flows

```python
# A "preparation flow": starting from identity, the circuit prepares a stabilizer
assert circuit.has_flow(stim.Flow("1 -> Z0*Z1*Z2*Z3 xor rec[-1]"))

# A "measurement flow": an input stabilizer collapses to a measurement
assert circuit.has_flow(stim.Flow("X0*X1*X2*X3 -> rec[-2]"))

# A "preserved flow": stabilizer passes through unchanged
assert circuit.has_flow(stim.Flow("Z0*Z1 -> Z0*Z1"))
```

### Batch Verification

```python
assert circuit.has_all_flows([
    stim.Flow("Z0*Z1 -> Z0*Z1"),
    stim.Flow("X0*X1*X2 -> X0*X1*X2"),
    stim.Flow("1 -> Z0*Z2 xor rec[-1]"),
], unsigned=True)  # unsigned=True ignores sign (phase) differences
```

### Solving for Measurement Contributions

When you know the input/output Paulis but not which measurements mediate the flow:

```python
solutions = circuit.solve_flow_measurements([
    stim.Flow("Z0 -> 1"),  # Which measurement(s) capture Z0?
])
# Returns list of Optional[list[int]]
```

## The Chunk/Flow Mental Model

The chunk/flow model (from the `gen` library) structures QEC circuits as
composable pieces:

- **Chunk**: A circuit fragment with declared in-flows and out-flows
- **In-flow**: A stabilizer that enters the chunk (must be present at the start)
- **Out-flow**: A stabilizer that exits the chunk (present at the end)
- **Measurement flow**: A stabilizer that gets collapsed to a measurement

When composing chunks sequentially, the out-flows of one chunk match the
in-flows of the next. Closed flow compositions (where all flows connect)
form **detection regions**, which become **detectors**.

Typical construction pattern:
1. Build a single stabilizer extraction round as a chunk
2. Compose multiple rounds, matching in/out flows
3. Add initialization and termination chunks
4. The matched flows automatically define detectors

## Noise Insertion

The bundled `scripts/noise_model.py` provides two standard models:

```python
import sys
sys.path.insert(0, "<path-to-skill>/scripts")
from noise_model import NoiseModel

# Uniform depolarizing: same parameter p everywhere
model = NoiseModel.uniform_depolarizing(p=0.001)
noisy_circuit = model.noisy_circuit(noiseless_circuit)

# Superconducting-inspired (SI1000): different rates for different operations
model = NoiseModel.si1000(p=0.001)
noisy_circuit = model.noisy_circuit(noiseless_circuit)
```

Copy `scripts/noise_model.py` into the user's project for standalone use.

### Generating Multiple Noise Strengths

```python
noise_strengths = [5e-4, 1e-3, 2e-3]
for p in noise_strengths:
    model = NoiseModel.uniform_depolarizing(p)
    noisy = model.noisy_circuit(noiseless_circuit)
    noisy.to_file(f"out/circuits/d={distance}_p={p}.stim")
```

## Detector Error Model (DEM)

The DEM describes which physical errors trigger which detectors and flip
which observables. It is the bridge between circuit-level noise and decoding.

### Building the DEM

```python
dem = noisy_circuit.detector_error_model(
    decompose_errors=True,    # Decompose into graphlike errors (needed for matching decoders)
    flatten_loops=False,      # Keep REPEAT blocks (faster for large circuits)
    allow_gauge_detectors=False,
    approximate_disjoint_errors=False,
)
```

If `detector_error_model()` raises an exception about **nondeterministic
detectors or observables**, the circuit has a bug:
- Check that every DETECTOR parity is truly deterministic under noiseless execution
- Use `circuit.has_flow()` to verify the stabilizer flows backing each detector
- Check for missing TICKs or incorrect measurement record indices

### Checking for Missing Detectors

```python
# Returns detector indices with zero-weight detection regions
missing = noiseless_circuit.missing_detectors()
if missing:
    print(f"WARNING: detectors {missing} have zero syndrome weight")
```

## Fault Distance Verification

### Graphlike Distance (for matchable codes)

```python
logical_errors = noisy_circuit.shortest_graphlike_error(
    ignore_ungraphlike_errors=False,  # Don't ignore non-graphlike errors
    canonicalize_circuit_errors=True,  # Use canonical representatives
)
fault_distance = len(logical_errors)
print(f"Fault distance: {fault_distance}")

if fault_distance < expected_distance:
    # Inspect the error configuration to debug
    for i, err in enumerate(logical_errors):
        print(f"Error {i}: {err}")
```

### Heuristic Search (for unmatchable codes)

```python
errors = noisy_circuit.search_for_undetectable_logical_errors(
    dont_explore_detection_event_sets_with_size_above=4,
    dont_explore_edges_with_degree_above=4,
    dont_explore_edges_increasing_symptom_degree=True,
    canonicalize_circuit_errors=True,
)
```

## Verification Workflow Summary

Follow this sequence before running simulations:

1. **Build noiseless circuit** with detectors and observables
2. **Insert noise** using the bundled noise model utility
3. **Build DEM** with `detector_error_model()` — fix any nondeterministic errors
4. **Check missing detectors** with `missing_detectors()`
5. **Verify fault distance** with `shortest_graphlike_error()` (matchable codes) or
   `search_for_undetectable_logical_errors()` (unmatchable codes)
6. If distance is as expected, proceed to simulation (see qec-simulation skill)
7. If distance is degraded, inspect `logical_errors` to debug the circuit structure

## Reference

Full Stim Python API: `doc/python_api_reference_vDev.md` in the Stim repository.
