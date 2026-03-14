"""Generate surface code memory circuits for sinter benchmarking.

Creates d=3,5,7 rotated surface code circuits with depolarizing noise,
saved with the comma-separated key=value naming convention that sinter's
`--metadata_func auto` understands.
"""

import pathlib
import stim

# ==============================================================================
# Circuit Parameters
# ==============================================================================

# Each entry: (code distance, physical error rate, rounds = distance).
# Rounds are set equal to distance, which is the standard choice for
# memory experiments -- it gives the decoder enough syndrome history
# to distinguish timelike from spacelike errors.
CONFIGS = [
    (3, 0.001, 3),
    (5, 0.001, 5),
    (7, 0.001, 7),
]

OUT_DIR = pathlib.Path("out/circuits")

# ==============================================================================
# Generation
# ==============================================================================

OUT_DIR.mkdir(parents=True, exist_ok=True)

for d, p, r in CONFIGS:
    circuit = stim.Circuit.generated(
        "surface_code:rotated_memory_z",
        distance=d,
        rounds=r,
        after_clifford_depolarization=p,
        after_reset_flip_probability=p,
        before_measure_flip_probability=p,
        before_round_data_depolarization=p,
    )

    # sinter's `comma_separated_key_values` parses filenames like
    # "d=3,p=0.001,r=3.stim" into metadata dicts like
    # {"d": 3, "p": 0.001, "r": 3}.
    filename = f"d={d},p={p},r={r}.stim"
    path = OUT_DIR / filename
    path.write_text(str(circuit))
    print(f"Wrote {path}  ({circuit.num_qubits} qubits, "
          f"{circuit.num_detectors} detectors, "
          f"{circuit.num_observables} observables)")
