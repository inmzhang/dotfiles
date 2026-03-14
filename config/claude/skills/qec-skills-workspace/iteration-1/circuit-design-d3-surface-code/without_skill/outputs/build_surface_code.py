"""
Build a d=3 rotated surface code memory-Z circuit from scratch using Stim.

This constructs the circuit manually (not using stim.Circuit.generated) with:
  - 9 data qubits, 4 X-type stabilizer ancillas, 4 Z-type stabilizer ancillas
  - 3 rounds of syndrome extraction
  - Uniform depolarizing noise at p=0.001
  - Detectors comparing syndrome measurements across rounds
  - A logical Z observable along the top row of data qubits

The script verifies the circuit by building a DEM and checking the fault distance.
"""

import stim

# ==============================================================================
# Qubit Layout for d=3 Rotated Surface Code
# ==============================================================================
#
# We use the coordinate convention from Stim's internal generator:
# data qubits live at (2*col+1, 2*row+1) for col,row in {0,1,2}
# measure qubits live at even coordinates (2*col, 2*row).
#
# For d=3, the coordinate grid (showing qubit roles) looks like:
#
#     0   1   2   3   4   5   6
# 0       Z       X
# 1   d       d       d
# 2   X       Z       X
# 3       d       d       d
# 4   X       Z       X
# 5           d       d       d
# 6           Z       X
#
# Where d=data, X=X-stabilizer ancilla, Z=Z-stabilizer ancilla.

d = 3
p = 0.001
num_rounds = 3

# ---- Enumerate data qubit positions ----
# Data qubits at (2*x+1, 2*y+1) for x in [0..d-1], y in [0..d-1].
data_coords = []
for x in range(d):
    for y in range(d):
        data_coords.append((2 * x + 1, 2 * y + 1))
data_coords.sort()

# ---- Enumerate stabilizer (measure) qubit positions ----
# Measure qubits at even coordinates (2*x, 2*y) for x in [0..d], y in [0..d],
# subject to boundary conditions. The parity of (x+y) determines X vs Z type.
x_measure_coords = []
z_measure_coords = []
for x in range(d + 1):
    for y in range(d + 1):
        coord = (2 * x, 2 * y)
        on_x_boundary = (x == 0 or x == d)
        on_y_boundary = (y == 0 or y == d)
        parity = (x % 2) != (y % 2)  # True => X type, False => Z type

        # Boundary exclusion rules: X-type qubits are excluded from the
        # left/right (x) boundaries; Z-type from the top/bottom (y) boundaries.
        if on_x_boundary and parity:
            continue
        if on_y_boundary and (not parity):
            continue

        if parity:
            x_measure_coords.append(coord)
        else:
            z_measure_coords.append(coord)

x_measure_coords.sort()
z_measure_coords.sort()
measure_coords = x_measure_coords + z_measure_coords

# ---- Assign qubit indices ----
# Use Stim's convention: index = x_coord + y_coord * stride, with an offset
# to pack measure qubits (at even coords) and data qubits (at odd coords)
# into a contiguous range. We replicate the formula from Stim's generator:
#   q = coord - (0, coord_x % 2)  then  index = q.x + q.y * (d + 0.5)
# (using the *scaled* coordinates, so coord_x is already 2*col+1 etc.)
def coord_to_index(c):
    cx, cy = c
    # Shift y down by (cx % 2) to pack the grid.
    cy_shifted = cy - (cx % 2)
    stride = 2 * d + 1  # = 7 for d=3, matching (d + 0.5) * 2
    return cx + cy_shifted * stride


all_coords = data_coords + x_measure_coords + z_measure_coords
coord_to_q = {c: coord_to_index(c) for c in all_coords}

# Sorted qubit index lists, needed for applying gates in deterministic order.
data_qubits = sorted(coord_to_q[c] for c in data_coords)
x_measure_qubits = sorted(coord_to_q[c] for c in x_measure_coords)
z_measure_qubits = sorted(coord_to_q[c] for c in z_measure_coords)
measure_qubits = sorted(coord_to_q[c] for c in measure_coords)
all_qubits = sorted(set(data_qubits + measure_qubits))

# Build reverse maps for detector construction.
# measure_order[coord] gives the position of that measure qubit in the sorted
# measurement qubit list, which determines its offset in the measurement record.
measure_order = {}
for i, q in enumerate(measure_qubits):
    for c, idx in coord_to_q.items():
        if idx == q:
            measure_order[c] = i
            break

data_order = {}
for i, q in enumerate(data_qubits):
    for c, idx in coord_to_q.items():
        if idx == q:
            data_order[c] = i
            break

# ==============================================================================
# CNOT Interaction Orders (Hook-Error Optimized)
# ==============================================================================
#
# The CNOT order is chosen so that hook errors (two-qubit gate failures that
# propagate through subsequent CNOTs) create errors that run perpendicular to
# the logical observable, rather than parallel to it. This is critical for
# achieving the full code distance.
#
# For Z stabilizers (CNOT from data -> ancilla): NE, SE, NW, SW
# For X stabilizers (CNOT from ancilla -> data): NE, NW, SE, SW
# In our coordinate system where +x is right and +y is down:

z_deltas = [(+1, +1), (+1, -1), (-1, +1), (-1, -1)]
x_deltas = [(+1, +1), (-1, +1), (+1, -1), (-1, -1)]


# ==============================================================================
# Logical Observable
# ==============================================================================
#
# For memory-Z, the logical Z observable runs along the top row of data qubits
# (those with the smallest y coordinate = 1).
z_observable_coords = [(2 * x + 1, 1) for x in range(d)]

# ==============================================================================
# Helper: Build CNOT Targets for One Time Step
# ==============================================================================
def get_cnot_targets(step_index):
    """Return list of (control, target) pairs for CNOT step `step_index` (0-3).

    X stabilizers: ancilla is control, data is target (measures X-type parity).
    Z stabilizers: data is control, ancilla is target (measures Z-type parity).
    """
    targets = []
    x_delta = x_deltas[step_index]
    z_delta = z_deltas[step_index]

    for mc in x_measure_coords:
        dc = (mc[0] + x_delta[0], mc[1] + x_delta[1])
        if dc in coord_to_q:
            # X stabilizer: ancilla controls data
            targets.append(coord_to_q[mc])
            targets.append(coord_to_q[dc])

    for mc in z_measure_coords:
        dc = (mc[0] + z_delta[0], mc[1] + z_delta[1])
        if dc in coord_to_q:
            # Z stabilizer: data controls ancilla
            targets.append(coord_to_q[dc])
            targets.append(coord_to_q[mc])

    return targets


# ==============================================================================
# Circuit Construction
# ==============================================================================

circuit = stim.Circuit()

# ---- QUBIT_COORDS declarations ----
for c in sorted(all_coords, key=lambda c: coord_to_q[c]):
    q = coord_to_q[c]
    circuit.append("QUBIT_COORDS", [q], [c[0], c[1]])

# ---- Initial reset of all qubits ----
# Memory-Z: data qubits start in |0> (Z-basis reset), ancillas in |0>.
circuit.append("R", data_qubits)
circuit.append("R", measure_qubits)

# ---- Noise on idle data qubits after reset (to model preparation errors) ----
circuit.append("DEPOLARIZE1", data_qubits, p)
circuit.append("DEPOLARIZE1", measure_qubits, p)

circuit.append("TICK", [])

# ==============================================================================
# Syndrome Extraction Round (as a reusable sub-circuit)
# ==============================================================================
#
# Each round consists of:
# 1. H on X-type ancillas (to start X-basis measurement)
# 2. Four CNOT steps (with noise after each)
# 3. H on X-type ancillas (to finish X-basis measurement)
# 4. Measure and reset ancillas


def append_syndrome_round(circ):
    """Append one syndrome extraction round to the circuit."""
    # Hadamard on X-type ancillas to prepare them in the X basis.
    circ.append("H", x_measure_qubits)
    circ.append("DEPOLARIZE1", x_measure_qubits, p)
    circ.append("TICK", [])

    # Four CNOT interaction steps.
    for step in range(4):
        targets = get_cnot_targets(step)
        circ.append("CNOT", targets)
        circ.append("DEPOLARIZE2", targets, p)

        # Idle noise on qubits not involved in this CNOT step.
        active_qubits = set(targets)
        idle = [q for q in all_qubits if q not in active_qubits]
        if idle:
            circ.append("DEPOLARIZE1", idle, p)
        circ.append("TICK", [])

    # Hadamard on X-type ancillas to return to computational basis.
    circ.append("H", x_measure_qubits)
    circ.append("DEPOLARIZE1", x_measure_qubits, p)
    circ.append("TICK", [])

    # Measure and reset all ancillas.
    circ.append("MR", measure_qubits, p)


# ==============================================================================
# Round 1: First Syndrome Extraction + Initial Detectors
# ==============================================================================
#
# After the first round, each Z-stabilizer measurement should deterministically
# yield 0 (since data qubits were initialized in |0>). So these measurements
# are detectors on their own (not compared to a previous round). X-stabilizer
# measurements are NOT deterministic after Z-basis initialization, so they only
# become detectors starting from round 2 (when we compare consecutive rounds).
#
# For memory-Z, the "chosen basis" detectors in the first round are the
# Z-stabilizer ancillas.

append_syndrome_round(circuit)

# Detectors for round 1: only Z-type stabilizers are deterministic.
num_measure = len(measure_qubits)
for mc in z_measure_coords:
    m_offset = num_measure - measure_order[mc]
    circuit.append("DETECTOR", [stim.target_rec(-m_offset)], [mc[0], mc[1], 0])

circuit.append("SHIFT_COORDS", [], [0, 0, 1])
circuit.append("TICK", [])

# ==============================================================================
# Rounds 2..num_rounds: Repeated Syndrome Extraction + Comparison Detectors
# ==============================================================================
#
# In subsequent rounds, detectors compare the current measurement of every
# stabilizer against the previous round's measurement of the same stabilizer.
# A change indicates a detection event.

for rnd in range(1, num_rounds):
    append_syndrome_round(circuit)

    # Comparison detectors: current measurement XOR previous measurement.
    for mc in measure_coords:
        m_idx = measure_order[mc]
        # Current measurement: rec[-(num_measure - m_idx)]
        # Previous measurement: rec[-(2*num_measure - m_idx)]
        cur = -(num_measure - m_idx)
        prev = -(2 * num_measure - m_idx)
        circuit.append(
            "DETECTOR",
            [stim.target_rec(cur), stim.target_rec(prev)],
            [mc[0], mc[1], 0],
        )

    circuit.append("SHIFT_COORDS", [], [0, 0, 1])
    circuit.append("TICK", [])

# ==============================================================================
# Final Data Measurement + Terminal Detectors + Logical Observable
# ==============================================================================
#
# Measure all data qubits in the Z basis. Then construct detectors that compare
# the data measurement outcomes against the last round's stabilizer measurements.
# Each Z-stabilizer detector includes the data qubits it covers AND the last
# ancilla measurement for that stabilizer.
#
# The logical observable is the product of data qubit measurements along the
# Z observable (top row).

circuit.append("M", data_qubits, p)

num_data = len(data_qubits)
for mc in z_measure_coords:
    detector_targets = []

    # Add data qubit measurement results for this stabilizer's support.
    for delta in z_deltas:
        dc = (mc[0] + delta[0], mc[1] + delta[1])
        if dc in coord_to_q:
            d_offset = num_data - data_order[dc]
            detector_targets.append(stim.target_rec(-d_offset))

    # Add the last ancilla measurement for this stabilizer.
    m_offset = num_data + num_measure - measure_order[mc]
    detector_targets.append(stim.target_rec(-m_offset))

    circuit.append("DETECTOR", detector_targets, [mc[0], mc[1], 0])

# Logical Z observable: product of Z measurements on the top row of data qubits.
obs_targets = []
for c in z_observable_coords:
    d_offset = num_data - data_order[c]
    obs_targets.append(stim.target_rec(-d_offset))
circuit.append("OBSERVABLE_INCLUDE", obs_targets, 0)

# ==============================================================================
# Verification
# ==============================================================================

print("=" * 60)
print("d=3 Rotated Surface Code (Memory-Z, 3 Rounds, p=0.001)")
print("=" * 60)

# Circuit stats.
print(f"\nCircuit stats:")
print(f"  num_qubits:      {circuit.num_qubits}")
print(f"  num_detectors:   {circuit.num_detectors}")
print(f"  num_observables: {circuit.num_observables}")

# Build DEM.
try:
    dem = circuit.detector_error_model(decompose_errors=True)
    print(f"\nDEM built successfully.")
    print(f"  DEM num_detectors:   {dem.num_detectors}")
    print(f"  DEM num_observables: {dem.num_observables}")
    print(f"  DEM num_errors:      {dem.num_errors}")
except Exception as e:
    print(f"\nFailed to build DEM: {e}")
    raise

# Compute fault distance.
try:
    errors = circuit.shortest_graphlike_error()
    fault_distance = len(errors)
    print(f"\nFault distance: {fault_distance}")
    if fault_distance == d:
        print(f"  PASS: fault distance matches code distance d={d}")
    else:
        print(f"  FAIL: expected fault distance {d}, got {fault_distance}")
except Exception as e:
    print(f"\nFailed to compute fault distance: {e}")
    raise

# Print the circuit for inspection.
print(f"\n{'=' * 60}")
print("Full circuit:")
print("=" * 60)
print(circuit)
