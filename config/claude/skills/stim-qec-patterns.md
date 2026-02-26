---
name: stim-qec-patterns
description: Patterns for constructing, analyzing, and simulating quantum error correction circuits using the stim Python library.
version: 1.0.0
source: local-git-analysis + upstream API reference
---

# Stim QEC Circuit Patterns

This skill teaches how to use the [stim](https://github.com/quantumlib/Stim) Python library for constructing, analyzing, and simulating quantum error correction (QEC) circuits.

API reference: https://github.com/quantumlib/Stim/blob/main/doc/python_api_reference_vDev.md

---

## 1. Circuit Construction

### From String (Stim DSL)

```python
import stim

circuit = stim.Circuit("""
    R 0 1 2
    TICK
    H 0
    TICK
    CX 0 1
    TICK
    M 0 1
    DETECTOR rec[-1] rec[-2]
    OBSERVABLE_INCLUDE(0) rec[-1]
""")
```

### Programmatic Construction

```python
circuit = stim.Circuit()
circuit.append("QUBIT_COORDS", [0], [0.0, 0.0])
circuit.append("QUBIT_COORDS", [1], [1.0, 0.0])
circuit.append("R", [0, 1])
circuit.append("TICK")
circuit.append("H", [0])
circuit.append("TICK")
circuit.append("CX", [0, 1])
circuit.append("TICK")
circuit.append("M", [0, 1])
```

### `circuit.append()` Signature

```python
circuit.append(
    name: str,                    # Gate name: "H", "CX", "M", "DETECTOR", etc.
    targets: int | list | ...,    # Qubit indices, GateTargets, or PauliStrings
    arg: float | list | None,     # Gate parameter (e.g., error probability)
    *,
    tag: str = "",                # Optional tag attached to instruction
)

# Can also append entire instructions or circuits:
circuit.append(stim.CircuitInstruction(...))
circuit.append(other_circuit)
```

### Concatenation and Repetition

```python
combined = circuit_a + circuit_b

# Repeat blocks
body = stim.Circuit("H 0\nTICK\nM 0\nR 0\nTICK")
circuit.append(stim.CircuitRepeatBlock(repeat_count=100, body=body))

# Multiplication syntax
big_circuit = small_circuit * 5
```

### Circuit Properties

```python
circuit.num_qubits
circuit.num_measurements
circuit.num_detectors
circuit.num_observables
circuit.num_ticks
```

### Circuit Transformations

```python
flat = circuit.flattened()        # Expand all REPEAT blocks
clean = circuit.without_noise()   # Strip noise operations
copy = circuit.copy()
```

---

## 2. Gate Vocabulary

### Single-Qubit Cliffords

```python
circuit.append("H", [0])          # Hadamard (X<->Z)
circuit.append("S", [0])          # Phase gate (sqrt Z)
circuit.append("S_DAG", [0])      # Adjoint phase gate
circuit.append("SQRT_X", [0])     # sqrt(X)
circuit.append("SQRT_X_DAG", [0])
circuit.append("SQRT_Y", [0])     # sqrt(Y)
circuit.append("SQRT_Y_DAG", [0])
circuit.append("X", [0])          # Pauli X
circuit.append("Y", [0])          # Pauli Y
circuit.append("Z", [0])          # Pauli Z
circuit.append("C_XYZ", [0])      # X->Y->Z->X permutation
circuit.append("C_ZYX", [0])      # Z->Y->X->Z permutation
circuit.append("H_XY", [0])       # Hadamard (X<->Y)
circuit.append("H_YZ", [0])       # Hadamard (Y<->Z)
```

### Two-Qubit Gates

```python
circuit.append("CX", [0, 1])      # CNOT (ZCX): control=0, target=1
circuit.append("CY", [0, 1])      # Controlled-Y
circuit.append("CZ", [0, 1])      # Controlled-Z
circuit.append("XCX", [0, 1])     # X-controlled X
circuit.append("XCY", [0, 1])     # X-controlled Y
circuit.append("XCZ", [0, 1])     # X-controlled Z
circuit.append("YCX", [0, 1])     # Y-controlled X
circuit.append("YCY", [0, 1])     # Y-controlled Y
circuit.append("YCZ", [0, 1])     # Y-controlled Z
circuit.append("SWAP", [0, 1])
circuit.append("ISWAP", [0, 1])
circuit.append("ISWAP_DAG", [0, 1])
circuit.append("SQRT_XX", [0, 1])
circuit.append("SQRT_YY", [0, 1])
circuit.append("SQRT_ZZ", [0, 1])

# Multiple pairs in one instruction (parallel execution):
circuit.append("CX", [0, 1, 2, 3, 4, 5])  # CX 0->1, CX 2->3, CX 4->5
```

### Reset Operations

```python
circuit.append("R", [0, 1])       # Reset to |0> (Z-basis)
circuit.append("RX", [0])         # Reset to |+> (X-basis)
circuit.append("RY", [0])         # Reset to |i> (Y-basis)
```

### Measurement Operations

```python
circuit.append("M", [0, 1])       # Measure in Z-basis
circuit.append("MX", [0])         # Measure in X-basis
circuit.append("MY", [0])         # Measure in Y-basis
circuit.append("MR", [0])         # Measure then reset (Z-basis)
circuit.append("MRX", [0])        # Measure then reset (X-basis)
circuit.append("MRY", [0])        # Measure then reset (Y-basis)

# Two-qubit parity measurements
circuit.append("MXX", [0, 1])     # Measure X*X parity
circuit.append("MYY", [0, 1])     # Measure Y*Y parity
circuit.append("MZZ", [0, 1])     # Measure Z*Z parity

# Inverted measurement (flip result)
circuit.append("M", [0, stim.target_inv(1)])  # !1 in DSL
```

### Multi-Qubit Pauli Product Measurement (MPP)

MPP is the key instruction for QEC stabilizer measurements. It measures the
eigenvalue of an arbitrary Pauli product in a single shot.

```python
# Method 1: Using PauliString (convenient)
circuit.append("MPP", [stim.PauliString("X0*X1*X2")])

# Method 2: Using target_combined_paulis
circuit.append("MPP", [
    *stim.target_combined_paulis(stim.PauliString("X0*Z1*Z2")),
])

# Method 3: Using target_pauli + target_combiner (explicit)
circuit.append("MPP", [
    stim.target_pauli(0, "X"),
    stim.target_combiner(),
    stim.target_pauli(1, "Z"),
    stim.target_combiner(),
    stim.target_pauli(2, "Z"),
])

# Multiple products in one MPP instruction (each produces one measurement):
circuit.append("MPP", [
    *stim.target_combined_paulis(stim.PauliString("X0*X1")),
    *stim.target_combined_paulis(stim.PauliString("Z1*Z2")),
])
```

---

## 3. Annotations

### TICK (Time Boundaries)

`TICK` separates circuit moments. It has no physical effect but is essential
for marking time steps, enabling diagram generation, and structuring noise
models (idle qubits get noise between TICKs).

```python
circuit.append("TICK")
```

### QUBIT_COORDS and SHIFT_COORDS

Assign spatial/temporal coordinates to qubits for visualization and
diagnostics. Coordinates are metadata only; they don't affect simulation.

```python
circuit.append("QUBIT_COORDS", [0], [0.0, 0.0])   # qubit 0 at (0, 0)
circuit.append("QUBIT_COORDS", [1], [1.0, 0.0])   # qubit 1 at (1, 0)

# Shift the coordinate origin (useful in REPEAT blocks for time axis)
circuit.append("SHIFT_COORDS", [], [0, 0, 1])      # shift 3rd coord by 1

# Retrieve coordinates later:
coords = circuit.get_final_qubit_coordinates()  # dict[int, list[float]]
```

### Measurement Record References

Stim uses **negative indexing** into a global measurement record. The most
recent measurement is `rec[-1]`, the one before that is `rec[-2]`, etc.

```python
stim.target_rec(-1)     # Most recent measurement
stim.target_rec(-2)     # Second-most-recent

# Example: classical feedback (CX conditioned on measurement)
circuit.append("M", [5, 7, 11])
circuit.append("CX", [stim.target_rec(-2), 3])  # Feed rec[-2] into qubit 3
```

### DETECTOR

A detector declares a parity of measurements that should be deterministic
under noiseless execution. When noise flips the parity, the detector fires.

```python
# XOR of two measurements should be 0 in noiseless case
circuit.append("DETECTOR", [stim.target_rec(-1), stim.target_rec(-5)])

# With coordinates for visualization (x, y, t):
circuit.append("DETECTOR", [stim.target_rec(-1), stim.target_rec(-2)], [1.0, 2.0, 0])
```

### OBSERVABLE_INCLUDE

Declares that a measurement contributes to a logical observable. Stim
tracks how errors flip observables to determine logical error rates.

```python
# Measurement rec[-1] contributes to observable 0
circuit.append("OBSERVABLE_INCLUDE", [stim.target_rec(-1)], 0)
```

---

## 4. Noise Channels

Noise instructions model errors. They are ignored by `has_flow` but are
essential for `detector_error_model()` and sampling.

### Single-Qubit Noise

```python
# Depolarizing: randomly apply I, X, Y, or Z with total probability p
circuit.append("DEPOLARIZE1", [0, 1, 2], 0.001)

# Single Pauli errors
circuit.append("X_ERROR", [0], 0.01)
circuit.append("Y_ERROR", [0], 0.01)
circuit.append("Z_ERROR", [0], 0.01)

# General Pauli channel: P(X)=px, P(Y)=py, P(Z)=pz
circuit.append("PAULI_CHANNEL_1", [0], [0.01, 0.02, 0.005])
```

### Two-Qubit Noise

```python
# Two-qubit depolarizing: randomly apply one of 15 non-II Pauli products
circuit.append("DEPOLARIZE2", [0, 1], 0.01)

# General two-qubit Pauli channel (15 probabilities: IX, IY, IZ, XI, XX, ...)
circuit.append("PAULI_CHANNEL_2", [0, 1], [0.001] * 15)
```

### Correlated Errors

```python
# Correlated error: applies specified Paulis with probability p
circuit.append("CORRELATED_ERROR", [stim.target_x(0), stim.target_y(2)], 0.25)

# Short form: E (alias for CORRELATED_ERROR)
# In DSL: E(0.25) X0 Y2

# ELSE_CORRELATED_ERROR: conditional on previous error NOT occurring
circuit.append("ELSE_CORRELATED_ERROR", [stim.target_z(1)], 0.1)
```

### Measurement Noise

Measurement noise is typically modeled by placing `X_ERROR` before `M`
(for Z-basis measurement) or `Z_ERROR` before `MX`:

```python
circuit.append("X_ERROR", [0], 0.005)   # Bit-flip before Z measurement
circuit.append("M", [0])

# Or use measurement with built-in flip probability:
# M(0.005) 0  (in DSL — applies X_ERROR before the measurement)
```

---

## 5. Pre-Built Circuit Generation

```python
# Generate standard QEC memory experiment circuits with noise
circuit = stim.Circuit.generated(
    code_task="surface_code:rotated_memory_z",
    distance=3,
    rounds=10,
    after_clifford_depolarization=0.001,
    before_round_data_depolarization=0.0,
    before_measure_flip_probability=0.0,
    after_reset_flip_probability=0.0,
)

# Available code_task values:
# - "repetition_code:memory"
# - "surface_code:rotated_memory_x"
# - "surface_code:rotated_memory_z"
# - "surface_code:unrotated_memory_x"
# - "surface_code:unrotated_memory_z"
# - "color_code:memory_xyz"
```

The generated circuits include DETECTOR, OBSERVABLE_INCLUDE, TICK,
QUBIT_COORDS, and noise annotations, ready for sampling and analysis.

---

## 6. PauliString

### Construction

```python
# From dense string
ps = stim.PauliString("XYZ")        # X0*Y1*Z2
ps = stim.PauliString("-XYZ")       # With sign
ps = stim.PauliString("+i_XZ")      # With imaginary sign, identity on qubit 0

# From sparse string
ps = stim.PauliString("X2*Y6")      # Only specified qubits are non-identity

# From integer (identity of given length)
ps = stim.PauliString(5)            # +_____

# From dict (qubit -> pauli)
ps = stim.PauliString({0: "X", 2: "Y", 3: "Z"})

# From dict (pauli -> qubit list)
ps = stim.PauliString({"X": [0, 1], "Z": [3, 4]})
```

### Properties and Methods

```python
ps.sign          # +1, -1, +1j, or -1j
ps.weight        # Number of non-identity terms
ps[0]            # Pauli at qubit 0 (returns 0=I, 1=X, 2=Y, 3=Z)
ps[0] = "X"      # Set Pauli at qubit 0
len(ps)          # Length (num qubits)

ps.pauli_indices()  # List of qubit indices with non-identity Paulis

# Algebra
product = ps1 * ps2          # Pauli product (with sign tracking)
ps.commutes(other_ps)        # True if they commute

# Conjugation by Clifford circuits
ps.after(circuit)            # Heisenberg picture: transform ps through circuit
ps.before(circuit)           # Inverse Heisenberg picture

# Random
random_ps = stim.PauliString.random(num_qubits=10)
```

---

## 7. Flow (Stabilizer Flow Verification)

A flow `P -> Q` means the circuit transforms stabilizer P (at input) to Q
(at output), potentially mediated by measurements.

### Construction

```python
# From shorthand string (most convenient)
flow = stim.Flow("X -> Z")
flow = stim.Flow("XX -> _X xor rec[-1]")
flow = stim.Flow("Z -> rec[-1]")           # Measurement flow (output=identity)
flow = stim.Flow("1 -> Z")                 # Preparation flow (input=identity)
flow = stim.Flow("-Y -> Y")                # With sign

# From explicit components
flow = stim.Flow(
    input=stim.PauliString("+X_"),
    output=stim.PauliString("+_X"),
    measurements=[0],               # Measurement indices mediating the flow
)

# With observable tracking
flow = stim.Flow("X5 -> obs[3]")    # Input X5 ends up in observable 3
flow = stim.Flow(
    input=stim.PauliString("X"),
    included_observables=[3],
)
```

### Verifying Flows

```python
# Does the circuit have this flow?
circuit.has_flow(stim.Flow("X -> Z"))                # Exact sign check
circuit.has_flow(stim.Flow("Y -> Y"), unsigned=True)  # Ignore sign

# Batch check (faster than checking one at a time)
circuit.has_all_flows([
    stim.Flow("X -> Z"),
    stim.Flow("Y -> -Y"),
    stim.Flow("Z -> X"),
])

# Flow algebra: multiply flows
combined = stim.Flow("X -> X") * stim.Flow("Z -> Z")  # => Y -> Y
```

### Solving for Measurement Indices

When you know the input/output Paulis but not which measurements mediate
the flow:

```python
solutions = circuit.solve_flow_measurements([
    stim.Flow("Z -> 1"),         # Which measurement(s) capture Z?
    stim.Flow("X0*X2 -> X0*X2"), # Which measurement(s) preserve X0*X2?
])
# Returns list of Optional[list[int]], None if no solution exists
```

### Flow Generators

Get a basis of all stabilizer flows through a circuit:

```python
flows = circuit.flow_generators()
# Returns a list of stim.Flow objects spanning the flow space
```

---

## 8. Detector Error Model (DEM)

The DEM describes which physical errors trigger which detectors and flip
which observables. It's the bridge between circuit-level noise and
decoding.

### Extraction

```python
dem = circuit.detector_error_model(
    decompose_errors=False,           # Decompose composite errors into graphlike parts
    flatten_loops=False,              # Expand REPEAT blocks (expensive for large circuits)
    allow_gauge_detectors=False,      # Allow non-deterministic detectors
    approximate_disjoint_errors=False, # Approximate disjoint error channels as independent
    ignore_decomposition_failures=False,
    block_decomposition_from_introducing_remnant_edges=False,
)
```

### Iterating Over Error Mechanisms

```python
for instruction in dem.flattened():
    if instruction.type == "error":
        probability = instruction.args_copy()[0]
        detectors = set()
        observables = set()
        for target in instruction.targets_copy():
            if target.is_relative_detector_id():
                detectors.add(target.val)
            elif target.is_logical_observable_id():
                observables.add(target.val)

        if observables and not detectors:
            print(f"Undetectable logical error! p={probability}")
```

### DEM Properties

```python
dem.num_detectors
dem.num_errors
dem.num_observables
det_coords = dem.get_detector_coordinates()  # dict[int, list[float]]
```

---

## 9. Distance Verification and Error Search

### Shortest Graphlike Error

Finds the minimum number of graphlike errors (each flipping at most 2
detectors) that combine to flip a logical observable undetectably.

```python
errors = circuit.shortest_graphlike_error(
    ignore_ungraphlike_errors=True,     # Skip non-graphlike errors
    canonicalize_circuit_errors=False,  # Use one representative per symptom set
)
code_distance = len(errors)
```

### Heuristic Search (Includes Hyperedges)

More thorough but heuristic. Considers errors that flip >2 detectors.

```python
errors = circuit.search_for_undetectable_logical_errors(
    dont_explore_detection_event_sets_with_size_above=4,  # Max intermediate symptoms
    dont_explore_edges_with_degree_above=4,               # Max detectors per error
    dont_explore_edges_increasing_symptom_degree=True,    # Prune growing symptoms
    canonicalize_circuit_errors=True,
)
# Returns list[stim.ExplainedError]
```

### Explaining Errors

Get detailed circuit-level explanations of how errors propagate:

```python
explained = circuit.explain_detector_error_model_errors(
    dem_filter=filtered_dem,                  # Only explain these DEM errors
    reduce_to_one_representative_error=True,  # One circuit error per DEM error
)
# Returns list[stim.ExplainedError]
# Each has .circuit_error_locations and .dem_error_terms
```

### MaxSAT Distance Computation

For exact distance computation using external solvers:

```python
problem = circuit.shortest_error_sat_problem(format="WDIMACS")
# Feed to a maxSAT solver (e.g., pysat RC2) for exact minimum weight
```

---

## 10. Detecting Regions

Find where (in spacetime) each detector/observable is sensitive to errors:

```python
regions = circuit.detecting_regions(
    targets=["D5", "L0", (2, 4)],  # Filter by detector, observable, or coord prefix
    ticks=range(5, 15),             # Which ticks to query
)
# Returns dict[DemTarget, dict[int, PauliString]]
# e.g., regions[stim.target_logical_observable_id(0)][tick] = PauliString("X_X_X")

for target, tick_regions in regions.items():
    print(f"target {target}")
    for tick, sensitivity in tick_regions.items():
        print(f"  tick {tick}: {sensitivity}")
```

---

## 11. Time Reversal

Transform a preparation circuit into a measurement circuit (and vice versa):

```python
inv_circuit, inv_flows = circuit.time_reversed_for_flows(
    flows=[
        stim.Flow("1 -> Z"),    # Preparation becomes measurement
        stim.Flow("X -> X"),    # Preserved stabilizer stays preserved
    ],
    dont_turn_measurements_into_resets=False,
)
# inv_circuit has the reversed structure
# inv_flows has the reversed flow specifications
# R becomes M, M becomes R, gates become their inverses
```

---

## 12. Sampling and Simulation

### Measurement Sampling

```python
sampler = circuit.compile_sampler(seed=42)
measurements = sampler.sample(shots=10000)
# measurements.shape = (10000, num_measurements), dtype=np.bool_

# Bit-packed for efficiency:
measurements = sampler.sample(shots=10000, bit_packed=True)
# measurements.shape = (10000, ceil(num_measurements/8)), dtype=np.uint8
```

### Detection Event Sampling

```python
sampler = circuit.compile_detector_sampler(seed=42)
detection_events = sampler.sample(shots=10000)
# detection_events.shape = (10000, num_detectors + num_observables)

# With observables separated:
det_events, obs_flips = sampler.sample(shots=10000, separate_observables=True)
# det_events.shape = (10000, num_detectors)
# obs_flips.shape = (10000, num_observables)
```

### Measurements to Detection Events Converter

Convert raw measurement data into detection events after the fact:

```python
converter = circuit.compile_m2d_converter()
detection_events = converter.convert(
    measurements=raw_measurements,  # np.bool_ array
    append_observables=True,
)
```

### Reference Sample

Get a single noiseless sample (useful for XOR-based decoding):

```python
ref = circuit.reference_sample()  # np.bool_ array of shape (num_measurements,)
```

---

## 13. TableauSimulator (Clifford Simulation)

Interactive Clifford-circuit simulation with measurement and state inspection.

```python
sim = stim.TableauSimulator(seed=0)

# Apply gates
sim.h(0)
sim.cx(0, 1)
sim.s(0)
sim.sqrt_x(2)
sim.cz(0, 2)
sim.swap(1, 2)

# Reset
sim.reset(0)             # Reset to |0>
sim.reset_x(0)           # Reset to |+>
sim.reset_y(0)           # Reset to |i>

# Measure
result = sim.measure(0)           # Measure qubit 0 in Z basis
results = sim.measure_many(0, 1, 2)  # Measure multiple qubits

# Measure a Pauli observable
obs = sim.measure_observable(stim.PauliString("X0*Z1*Z2"))

# Peek (non-destructive, returns -1, 0, or +1)
sim.peek_x(0)   # <X> expectation for qubit 0
sim.peek_y(0)   # <Y>
sim.peek_z(0)   # <Z>
sim.peek_bloch(0)  # Returns (px, py, pz) Bloch vector
sim.peek_observable_expectation(stim.PauliString("XX"))  # Multi-qubit

# Execute an entire circuit
sim.do(circuit)
sim.do_circuit(circuit)    # alias
sim.do_pauli_string(stim.PauliString("XYZ"))

# State inspection
stabilizers = sim.canonical_stabilizers()       # List[stim.PauliString]
state_vec = sim.state_vector(endian="little")   # numpy complex array
record = sim.current_measurement_record()       # list[bool]

# Initialize from stabilizers
sim.set_state_from_stabilizers([
    stim.PauliString("+XX"),
    stim.PauliString("+ZZ"),
])

# Postselection
sim.postselect_z(0, desired_value=False)   # Force |0> outcome
sim.postselect_observable(stim.PauliString("+ZZ"), desired_value=False)
```

---

## 14. Tableau (Clifford Algebra)

Represents a Clifford operation as a stabilizer tableau.

```python
# From a circuit
tableau = stim.Tableau.from_circuit(circuit)

# From a named gate
tableau = stim.Tableau.from_named_gate("H")

# Compose tableaux
combined = tableau_a * tableau_b     # Apply a then b
powered = tableau ** 3               # Apply 3 times

# Query stabilizer transformations
tableau.x_output(0)    # Where X0 maps to (PauliString)
tableau.z_output(0)    # Where Z0 maps to

# Convert back
circuit = tableau.to_circuit()
```

---

## 15. Target Helper Functions

```python
# Measurement record reference
stim.target_rec(-1)               # rec[-1]: most recent measurement

# Pauli targets (for MPP, CORRELATED_ERROR, etc.)
stim.target_x(qubit_index)        # X on qubit
stim.target_y(qubit_index)        # Y on qubit
stim.target_z(qubit_index)        # Z on qubit
stim.target_pauli(qubit, "X")     # General: qubit + pauli name or int
stim.target_pauli(qubit, "X", invert=True)  # Inverted: !X

# Combiner (for building multi-qubit Pauli products manually)
stim.target_combiner()             # The * in X2*Y3*Z5

# Combined paulis helper (returns list of targets for MPP)
targets = stim.target_combined_paulis(stim.PauliString("X0*Z1*Z2"))
targets = stim.target_combined_paulis([stim.target_x(0), stim.target_z(1)])

# Inverted measurement target
stim.target_inv(qubit_index)       # !qubit: flip measurement result

# Sweep bit (for batch simulation with varying classical bits)
stim.target_sweep_bit(bit_index)

# DEM targets (for building DetectorErrorModels)
stim.target_relative_detector_id(5)     # D5
stim.target_logical_observable_id(0)    # L0
stim.target_separator()                 # ^ separator between error components
```

---

## 16. Gate Introspection

```python
# Single gate
data = stim.gate_data("CX")
data.aliases               # ['CNOT', 'CX', 'ZCX']
data.is_unitary            # True
data.is_two_qubit_gate     # True
data.is_single_qubit_gate  # False
data.produces_measurements # False
data.is_reset              # False
data.is_noisy_gate         # False
data.tableau               # Stabilizer tableau (if Clifford)
data.unitary_matrix        # numpy array (if unitary)
data.num_parens_arguments_range  # range of allowed argument counts

# All gates
all_gates = stim.gate_data()  # dict[str, GateData]
measurement_gates = {name for name, g in all_gates.items() if g.produces_measurements}
```

---

## 17. Diagrams and Visualization

```python
# Text diagram
print(circuit.diagram("timeline-text"))

# SVG diagram
svg = circuit.diagram("timeline-svg")

# Interactive HTML (best for notebooks)
html = circuit.diagram("interactive-html")

# Detector slice diagram at specific ticks
svg = circuit.diagram("detslice-svg", tick=range(0, 5))

# Matching graph
svg = circuit.diagram("matchgraph-svg")

# Crumble URL (online interactive editor)
url = circuit.to_crumble_url()

# Available diagram types:
# "timeline-text", "timeline-svg", "timeline-svg-html", "timeline-3d",
# "timeline-3d-html", "detslice-text", "detslice-svg", "detslice-svg-html",
# "matchgraph-svg", "matchgraph-svg-html", "matchgraph-3d", "matchgraph-3d-html",
# "timeslice-svg", "timeslice-svg-html", "detslice-with-ops-svg",
# "detslice-with-ops-svg-html", "interactive", "interactive-html"
```

---

## 18. File I/O

```python
# Write circuit to file
circuit.to_file("my_circuit.stim")

# Read circuit from file
loaded = stim.Circuit.from_file("my_circuit.stim")

# Write/read shot data
stim.write_shot_data_file(
    data=detection_events,
    path="shots.b8",
    format="b8",
    num_detectors=circuit.num_detectors,
    num_observables=circuit.num_observables,
)

data = stim.read_shot_data_file(
    path="shots.b8",
    format="b8",
    num_detectors=circuit.num_detectors,
    num_observables=circuit.num_observables,
)
# Supported formats: "01", "b8", "r8", "ptb64", "hits", "dets"
```

---

## 19. Common QEC Workflow

### A: Build, Noise, Sample, Decode

```python
import stim
import numpy as np

# 1. Generate or build a QEC circuit
circuit = stim.Circuit.generated(
    "surface_code:rotated_memory_z",
    distance=3,
    rounds=10,
    after_clifford_depolarization=0.001,
)

# 2. Check code distance
num_errors = len(circuit.shortest_graphlike_error())
print(f"Code distance (graphlike): {num_errors}")

# 3. Extract DEM for decoder
dem = circuit.detector_error_model(decompose_errors=True)

# 4. Sample detection events
sampler = circuit.compile_detector_sampler()
det_events, obs_flips = sampler.sample(shots=10000, separate_observables=True)

# 5. Decode (e.g., with pymatching)
import pymatching
matcher = pymatching.Matching.from_detector_error_model(dem)
predicted_obs = matcher.decode_batch(det_events)

# 6. Compute logical error rate
num_logical_errors = np.sum(predicted_obs != obs_flips)
logical_error_rate = num_logical_errors / det_events.shape[0]
print(f"Logical error rate: {logical_error_rate}")
```

### B: Verify Custom Circuit Flows

```python
import stim

# Build a custom circuit
circuit = stim.Circuit("""
    R 0 1 2
    TICK
    CX 0 1
    CX 2 1
    TICK
    MR 1
""")

# Verify stabilizer flows
assert circuit.has_all_flows([
    stim.Flow("Z0*Z2 -> Z0*Z2"),                    # ZZ stabilizer preserved
    stim.Flow("1 -> Z0*Z2 xor rec[-1]"),             # Stabilizer measured into rec
    stim.Flow("X0*X1*X2 -> X0*X1*X2"),               # X stabilizer preserved
], unsigned=True)
```

### C: Build a Repetition Code Round from Scratch

```python
import stim

def make_repetition_code(distance: int, rounds: int, p: float) -> stim.Circuit:
    """Build a distance-d repetition code with depolarizing noise."""
    num_data = distance
    num_measure = distance - 1

    circuit = stim.Circuit()

    # Qubit coordinates
    for i in range(num_data + num_measure):
        circuit.append("QUBIT_COORDS", [i], [i, 0])

    # Data qubits: 0, 2, 4, ...; Measure qubits: 1, 3, 5, ...
    data_qubits = list(range(0, 2 * num_data, 2))
    measure_qubits = list(range(1, 2 * num_measure, 2))

    # Initial reset
    circuit.append("R", data_qubits + measure_qubits)
    circuit.append("TICK")

    def append_round(circuit: stim.Circuit):
        # Left CNOTs
        pairs_left = []
        for mq in measure_qubits:
            pairs_left.extend([mq - 1, mq])
        circuit.append("CX", pairs_left)
        if p > 0:
            circuit.append("DEPOLARIZE2", pairs_left, p)
        circuit.append("TICK")

        # Right CNOTs
        pairs_right = []
        for mq in measure_qubits:
            pairs_right.extend([mq + 1, mq])
        circuit.append("CX", pairs_right)
        if p > 0:
            circuit.append("DEPOLARIZE2", pairs_right, p)
        circuit.append("TICK")

        # Measure and reset ancillas
        circuit.append("MR", measure_qubits)

    # First round
    append_round(circuit)
    for i, mq in enumerate(measure_qubits):
        circuit.append("DETECTOR", [stim.target_rec(-(num_measure - i))], [mq, 0])
    circuit.append("SHIFT_COORDS", [], [0, 1])

    # Repeated rounds
    body = stim.Circuit()
    append_round(body)
    for i, mq in enumerate(measure_qubits):
        body.append("DETECTOR", [
            stim.target_rec(-(num_measure - i)),
            stim.target_rec(-(2 * num_measure - i)),
        ], [mq, 0])
    body.append("SHIFT_COORDS", [], [0, 1])
    circuit.append(stim.CircuitRepeatBlock(rounds - 1, body))

    # Final data measurements
    circuit.append("M", data_qubits)
    for i, mq in enumerate(measure_qubits):
        left_data = -(num_data - i)
        right_data = -(num_data - i - 1)
        prev_measure = -(num_data + num_measure - i)
        circuit.append("DETECTOR", [
            stim.target_rec(left_data),
            stim.target_rec(right_data),
            stim.target_rec(prev_measure),
        ], [mq, 1])

    circuit.append("OBSERVABLE_INCLUDE", [stim.target_rec(-1)], 0)
    return circuit

# Usage
circuit = make_repetition_code(distance=5, rounds=10, p=0.001)
print(f"Distance: {len(circuit.shortest_graphlike_error())}")
```
