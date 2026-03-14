"""Plot logical error rate vs code distance from sinter stats CSV.

Reads the stats.csv produced by sinter collect and creates a plot of
logical error rate as a function of code distance, grouped by physical
error rate.
"""

import pathlib

import matplotlib
matplotlib.use("Agg")  # Non-interactive backend for headless environments
import matplotlib.pyplot as plt
import sinter

# ==========================================================================
# Configuration
# ==========================================================================

script_dir = pathlib.Path(__file__).parent
stats_path = script_dir / "stats.csv"
output_path = script_dir / "error_rate_vs_distance.png"

# ==========================================================================
# Load Statistics
# ==========================================================================

stats = sinter.read_stats_from_csv_files(str(stats_path))

# Print a summary of what was loaded.
print("Loaded stats:")
for s in stats:
    m = s.json_metadata
    error_rate = s.errors / max(1, s.shots)
    print(
        f"  d={m.get('d')}, p={m.get('p')}, r={m.get('r')}: "
        f"{s.errors}/{s.shots} errors ({error_rate:.2e} error rate)"
    )

# ==========================================================================
# Plot: Error Rate vs Code Distance
# ==========================================================================

fig, ax = plt.subplots(1, 1, figsize=(8, 6))

sinter.plot_error_rate(
    ax=ax,
    stats=stats,
    # x-axis: code distance
    x_func=lambda stat: stat.json_metadata.get("d", 0),
    # Group curves by physical error rate
    group_func=lambda stat: f'p={stat.json_metadata.get("p", "?")}',
    # Show error bars with max-likelihood estimation
    highlight_max_likelihood_factor=1e3,
)

ax.set_xlabel("Code Distance (d)")
ax.set_ylabel("Logical Error Rate (per round)")
ax.set_title("Surface Code: Logical Error Rate vs Code Distance")
ax.legend()
ax.grid(True, alpha=0.3)

fig.tight_layout()
fig.savefig(str(output_path), dpi=200)
print(f"\nPlot saved to {output_path}")
