"""Generate surface code circuit files for sinter simulation.

Uses stim.Circuit.generated() to create noisy surface code circuits at
multiple code distances, saving them with the key=value filename convention
that sinter's --metadata_func auto recognizes.
"""

import pathlib
import stim

# ==========================================================================
# Circuit Parameters
# ==========================================================================

# Code distances to simulate. Each distance d uses d rounds of syndrome
# extraction, matching the standard convention for surface code memory
# experiments.
distances = [3, 5, 7]
noise_strength = 0.001

output_dir = pathlib.Path(__file__).parent / "circuits"
output_dir.mkdir(parents=True, exist_ok=True)

# ==========================================================================
# Circuit Generation
# ==========================================================================

for d in distances:
    rounds = d  # Standard: number of syndrome extraction rounds equals distance

    # stim.Circuit.generated() produces a full noisy circuit for the
    # specified code, including noise channels at the given strength.
    # "surface_code:rotated_memory_z" is the standard rotated surface code
    # doing a Z-basis memory experiment.
    circuit = stim.Circuit.generated(
        "surface_code:rotated_memory_z",
        rounds=rounds,
        distance=d,
        after_clifford_depolarization=noise_strength,
        after_reset_flip_probability=noise_strength,
        before_measure_flip_probability=noise_strength,
        before_round_data_depolarization=noise_strength,
    )

    # Encode parameters in filename so sinter can auto-extract metadata.
    filename = f"d={d},p={noise_strength},r={rounds}.stim"
    filepath = output_dir / filename
    filepath.write_text(str(circuit))
    print(f"Wrote {filepath} ({circuit.num_qubits} qubits, {len(circuit)} instructions)")

print(f"\nGenerated {len(distances)} circuit files in {output_dir}/")
