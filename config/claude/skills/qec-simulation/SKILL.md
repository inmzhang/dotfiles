---
name: qec-simulation
description: >
  Run noisy QEC circuit simulations using sinter for sampling, decoding, and
  result analysis. Use this skill when the user wants to run Monte Carlo
  sampling of QEC circuits, set up sinter collect jobs, define custom decoders
  (bposd, chromobius, etc.), configure sampling parameters (max_shots,
  max_errors), analyze stats CSV files, plot error rate curves, threshold
  estimation, or anything involving sinter CLI or Python API. Also trigger
  when the user mentions logical error rate computation, decoder benchmarking,
  pymatching decoding, or error rate vs code distance plots.
---

# QEC Simulation with Sinter

This skill covers the full simulation workflow: noise model insertion,
parallel sampling with sinter, decoder configuration, and result plotting.

## Important: Sampling Takes a Long Time

Sinter sampling jobs are long-running processes (minutes to hours to days).
**Never run sinter collect directly in the conversation.** Instead, always:

1. Write a reusable **launch script** (shell script) for the sampling job
2. Explain to the user how to modify the script parameters
3. Tell the user how to start the job (e.g., `bash run_collect.sh`)
4. Show them how to monitor progress and resume interrupted jobs

This applies to both CLI and Python API workflows. The only exception is
very quick test runs (e.g., `--max_shots 1000 --max_errors 10`) used to
verify the pipeline works before the real run.

## Environment Setup

```bash
# Basic simulation with built-in decoders
uv run --with stim,sinter,pymatching python simulate.py

# With additional decoders
uv run --with stim,sinter,pymatching,fusion-blossom python simulate.py

# For QLDPC codes with BP-OSD decoder
uv run --with stim,sinter,ldpc python simulate.py

# For color codes with chromobius
uv run --with stim,sinter,chromobius python simulate.py

# sinter CLI (ensure it's on PATH)
uv run --with stim,sinter,pymatching sinter collect ...
```

## Preparing Noisy Circuits

If the circuit is noiseless, noise must be inserted before simulation.
Use the noise model utility from the qec-circuit-design skill, or add
noise manually:

```python
import stim

# Manual noise insertion example
circuit = stim.Circuit.from_file("noiseless.stim")

# Add DEPOLARIZE1 after single-qubit gates, DEPOLARIZE2 after two-qubit gates,
# X_ERROR after resets, and flip probability to measurements.
# See qec-circuit-design skill for the bundled noise_model.py utility.
```

### Generating Circuit Families

A typical simulation sweeps over code distances and noise strengths:

```python
from noise_model import NoiseModel

distances = [3, 5, 7]
noise_strengths = [5e-4, 1e-3, 2e-3]
rounds_per_distance = lambda d: d  # or d*3, etc.

for d in distances:
    noiseless = build_circuit(distance=d, rounds=rounds_per_distance(d))
    for p in noise_strengths:
        model = NoiseModel.uniform_depolarizing(p)
        noisy = model.noisy_circuit(noiseless)
        # Encode metadata in filename for sinter's auto metadata extraction
        noisy.to_file(f"out/circuits/d={d},p={p},r={rounds_per_distance(d)}.stim")
```

The filename pattern `key=value,key=value.stim` is recognized by sinter's
`--metadata_func auto`, which extracts the key-value pairs as JSON metadata.

## Sinter CLI

### sinter collect

The primary command for running simulations. Always wrap this in a launch script:

```bash
#!/usr/bin/env bash
# run_collect.sh — Launch sinter sampling job
# Usage: bash run_collect.sh
# Modify parameters below before running.
set -e

CIRCUITS="out/circuits/*.stim"
DECODERS="pymatching"
MAX_SHOTS=100_000_000
MAX_ERRORS=100
PROCESSES=auto
STATS_FILE="out/stats.csv"

uv run --with stim,sinter,pymatching \
    sinter collect \
    --circuits $CIRCUITS \
    --decoders $DECODERS \
    --max_shots $MAX_SHOTS \
    --max_errors $MAX_ERRORS \
    --processes $PROCESSES \
    --save_resume_filepath $STATS_FILE \
    --metadata_func auto
```

Save this as a shell script so the user can:
- Adjust `MAX_SHOTS`, `MAX_ERRORS`, `PROCESSES` before running
- Resume interrupted jobs (same `--save_resume_filepath` picks up where it left off)
- Run in the background with `nohup bash run_collect.sh &`

Key options:
- `--circuits`: Glob pattern for .stim circuit files
- `--decoders`: Space-separated decoder names (pymatching, fusion_blossom, etc.)
- `--max_shots`: Stop sampling a task after this many shots
- `--max_errors`: Stop sampling a task after this many logical errors (typically 100-1000)
- `--processes auto`: Use all available CPU cores
- `--save_resume_filepath`: Append results to CSV; resume from where it left off
- `--metadata_func auto`: Extract metadata from filenames like `d=5,p=0.001.stim`
- `--custom_decoders_module_function 'module:function'`: Load custom decoders

### Custom Decoders via CLI

```bash
# The module must define a function returning Dict[str, sinter.Decoder]
sinter collect \
    --circuits "out/circuits/*.stim" \
    --decoders bposd \
    --custom_decoders_module_function 'my_decoders:sinter_decoders' \
    --max_shots 100_000_000 \
    --max_errors 100 \
    --save_resume_filepath out/stats.csv \
    --metadata_func auto
```

With `PYTHONPATH=src` if the module is in a `src/` directory:
```bash
PYTHONPATH=src sinter collect \
    --custom_decoders_module_function 'my_package:sinter_decoders' \
    ...
```

### sinter plot

Generate plots from collected statistics:

```bash
# Basic error rate plot
sinter plot \
    --in out/stats.csv \
    --type error_rate \
    --x_func "m.d" \
    --group_func "f'p={m.p}'" \
    --xaxis "[log]Code Distance" \
    --yaxis "[log]Logical Error Rate" \
    --out out/error_rate.png \
    --show

# With filtering
sinter plot \
    --in out/stats.csv \
    --type error_rate \
    --x_func "m.d" \
    --group_func "f'p={m.p}'" \
    --filter_func "m.p <= 0.01" \
    --xaxis "Code Distance" \
    --yaxis "[log]Logical Error Rate" \
    --out out/threshold.png

# Custom plot (e.g., discard rate vs attempts)
sinter plot \
    --in out/stats.csv \
    --type custom \
    --x_func "(stat.shots + 1) / (stat.shots - stat.discards + 2)" \
    --y_func "sinter.fit_binomial(num_hits=stat.errors, num_shots=stat.shots - stat.discards, max_likelihood_factor=1000)" \
    --group_func "f'd={m.d}'" \
    --xaxis "[log]Expected Attempts per Kept Shot" \
    --yaxis "[log]Logical Error Rate" \
    --out out/cost_curve.png
```

Expression variables available in `--x_func`, `--group_func`, `--filter_func`:
- `metadata` or `m`: The JSON metadata dict (with attribute access: `m.d`, `m.p`)
- `decoder`: The decoder name string
- `strong_id`: The task's cryptographic ID
- `stat`: The `TaskStats` object (has `.shots`, `.errors`, `.discards`, `.seconds`)

### sinter combine

Merge statistics from multiple CSV files:

```bash
sinter combine --in stats1.csv stats2.csv > combined.csv
```

## Sinter Python API

### Basic Collection

```python
import sinter
import stim

tasks = []
for path in sorted(pathlib.Path("out/circuits").glob("*.stim")):
    circuit = stim.Circuit.from_file(str(path))
    metadata = sinter.comma_separated_key_values(path.stem)  # parse d=5,p=0.001
    tasks.append(sinter.Task(
        circuit=circuit,
        decoder="pymatching",
        json_metadata=metadata,
    ))

results = sinter.collect(
    num_workers=8,
    tasks=tasks,
    max_shots=100_000_000,
    max_errors=100,
    print_progress=True,
)
```

### Custom Decoder Definition

```python
import numpy as np
import sinter
import stim

class BpOsdDecoder(sinter.Decoder):
    """Example custom decoder using BP-OSD from the ldpc package."""

    def compile_decoder_for_dem(self, *, dem: stim.DetectorErrorModel) -> sinter.CompiledDecoder:
        return BpOsdCompiledDecoder(dem)

class BpOsdCompiledDecoder(sinter.CompiledDecoder):
    def __init__(self, dem: stim.DetectorErrorModel):
        from ldpc import BpOsdDecoder as LdpcBpOsd
        # Build the check matrix from the DEM
        # ... (implementation depends on the specific decoder library)
        self.decoder = LdpcBpOsd(...)

    def decode_shots_bit_packed(
        self, *, bit_packed_detection_event_data: np.ndarray
    ) -> np.ndarray:
        # Input: (num_shots, ceil(num_detectors/8)) uint8
        # Output: (num_shots, ceil(num_observables/8)) uint8
        ...

# Register for sinter CLI usage
def sinter_decoders() -> dict[str, sinter.Decoder]:
    return {"bposd": BpOsdDecoder()}
```

The decoder object must be picklable (for multiprocessing). The `sinter_decoders`
function is what `--custom_decoders_module_function` calls.

### Plotting with Python API

```python
import matplotlib.pyplot as plt
import sinter

stats = sinter.read_stats_from_csv_files("out/stats.csv")

fig, ax = plt.subplots(1, 1, figsize=(10, 6))
sinter.plot_error_rate(
    ax=ax,
    stats=stats,
    x_func=lambda stat: stat.json_metadata.get("d", 0),
    group_func=lambda stat: f'p={stat.json_metadata.get("p", "?")}',
    filter_func=lambda stat: stat.json_metadata.get("p", 0) <= 0.01,
    highlight_max_likelihood_factor=1e3,
)
ax.set_xlabel("Code Distance")
ax.set_ylabel("Logical Error Rate")
ax.set_title("Surface Code Threshold")
ax.legend()
fig.savefig("out/threshold.png", dpi=200)
plt.show()
```

### Custom Plotting

```python
sinter.plot_custom(
    ax=ax,
    stats=stats,
    x_func=lambda stat: stat.json_metadata["d"],
    y_func=lambda stat: sinter.fit_binomial(
        num_hits=stat.errors,
        num_shots=stat.shots - stat.discards,
        max_likelihood_factor=1000,
    ),
    group_func=lambda stat: f'decoder={stat.decoder}',
)
```

### Streaming Collection with Progress

```python
for progress in sinter.iter_collect(
    num_workers=8,
    tasks=tasks,
    max_shots=100_000_000,
    max_errors=100,
):
    print(progress.status_message)
    for stat in progress.new_stats:
        print(f"  {stat.json_metadata}: {stat.errors}/{stat.shots} errors")
```

## Built-in Decoders

| Name | Description | Best for |
|------|-------------|----------|
| `pymatching` | Minimum-weight perfect matching | Surface codes, matchable codes |
| `fusion_blossom` | Fast MWPM implementation | Surface codes (faster for large instances) |
| `vacuous` | Always predicts no error | Baseline comparison |

Additional decoders available as separate packages:
- `chromobius`: Color code decoder (install: `uv pip install chromobius`)
- `ldpc` / `bposd`: BP-OSD for QLDPC codes (install: `uv pip install ldpc`)

## Simulation Workflow Summary

1. **Prepare circuits**: Build noiseless circuits, insert noise at multiple strengths
2. **Encode metadata in filenames**: Use `d=5,p=0.001,r=10.stim` pattern
3. **Write a launch script**: Create `run_collect.sh` with sinter collect parameters
4. **Tell the user to run it**: `bash run_collect.sh` (or `nohup bash run_collect.sh &`)
5. **Resume if interrupted**: Same `--save_resume_filepath` picks up automatically
6. **Plot results**: Write a separate plotting script using `sinter plot` or Python API
7. **Iterate**: If curves are noisy, increase `--max_errors`; if threshold is unclear,
   add more noise strengths or code distances

## Stats CSV Format

The CSV has columns: `shots,errors,discards,seconds,decoder,strong_id,json_metadata,custom_counts`

```python
# Load and inspect
stats = sinter.read_stats_from_csv_files("out/stats.csv")
for s in stats:
    m = s.json_metadata
    print(f"d={m.get('d')}, p={m.get('p')}: {s.errors}/{s.shots} errors "
          f"({s.errors/max(1,s.shots):.2e} error rate)")
```
