"""Plot logical error rate vs code distance from sinter CSV results.

Reads the CSV produced by `sinter collect`, groups by decoder, and
plots the logical error rate per shot on the Y axis against code
distance on the X axis.  Uncertainty bands reflect the likelihood
range from binomial fitting.
"""

import pathlib
import matplotlib
matplotlib.use("Agg")  # Non-interactive backend -- no display needed.
import matplotlib.pyplot as plt
import sinter

# ==============================================================================
# Load Statistics
# ==============================================================================

STATS_PATH = pathlib.Path("out/stats.csv")
stats = sinter.read_stats_from_csv_files(STATS_PATH)

print(f"Loaded {len(stats)} stat entries from {STATS_PATH}")
for s in stats:
    print(f"  d={s.json_metadata.get('d')}, "
          f"shots={s.shots}, errors={s.errors}, "
          f"decoder={s.decoder}")

# ==============================================================================
# Plot
# ==============================================================================

fig, ax = plt.subplots(1, 1, figsize=(8, 5))

sinter.plot_error_rate(
    ax=ax,
    stats=stats,
    # X axis: code distance, pulled from the auto-parsed metadata.
    x_func=lambda stat: stat.json_metadata["d"],
    # Each decoder gets its own curve (here we only have pymatching,
    # but this generalises if more decoders are added later).
    group_func=lambda stat: stat.decoder,
)

ax.set_xlabel("Code Distance (d)")
ax.set_ylabel("Logical Error Rate (per shot)")
ax.set_title("Surface Code: Logical Error Rate vs Code Distance\n"
             "(p = 0.001, rotated memory Z)")
ax.set_yscale("log")
ax.legend()
ax.grid(True, which="both", ls="--", alpha=0.4)

fig.tight_layout()

out_path = pathlib.Path("out/error_rate_vs_distance.png")
fig.savefig(out_path, dpi=150)
print(f"Saved plot to {out_path}")
