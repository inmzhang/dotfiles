#!/usr/bin/env bash
# run_all.sh -- Generate circuits, run sinter collect, and plot results.
#
# Usage:
#   cd /home/inm/open-source-project/Stim
#   bash /home/inm/.claude/skills/qec-skills-workspace/iteration-1/simulation-sinter-collect/without_skill/outputs/run_all.sh
#
# All outputs land in out/ under the Stim project directory.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Step 1: Generate test circuit files ==="
uv run --with stim,sinter,pymatching,matplotlib \
    python "$SCRIPT_DIR/generate_circuits.py"

echo ""
echo "=== Step 2: Run sinter collect (quick test: 1000 shots, 10 errors) ==="
uv run --with stim,sinter,pymatching,matplotlib \
    python -m sinter collect \
        --circuits out/circuits/*.stim \
        --decoders pymatching \
        --max_shots 1000 \
        --max_errors 10 \
        --processes auto \
        --metadata_func auto \
        --save_resume_filepath out/stats.csv

echo ""
echo "=== Step 3: Plot error rate vs code distance ==="
uv run --with stim,sinter,pymatching,matplotlib \
    python "$SCRIPT_DIR/plot_error_rate.py"

echo ""
echo "=== Done ==="
echo "Circuits:  out/circuits/"
echo "Stats CSV: out/stats.csv"
echo "Plot:      out/error_rate_vs_distance.png"
