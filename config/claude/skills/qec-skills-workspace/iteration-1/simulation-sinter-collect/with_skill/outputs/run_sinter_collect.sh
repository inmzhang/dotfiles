#!/bin/bash
# ==========================================================================
# Sinter Collect: Run pymatching decoding on surface code circuits
# ==========================================================================
#
# This script runs sinter collect to perform Monte Carlo sampling of the
# generated circuit files, using pymatching as the decoder.
#
# For production runs, use:
#   --max_shots 10_000_000
#   --max_errors 100
#
# For quick testing (as used here):
#   --max_shots 1000
#   --max_errors 10

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

uv run --with stim,sinter,pymatching \
    sinter collect \
    --circuits "${SCRIPT_DIR}/circuits/*.stim" \
    --decoders pymatching \
    --max_shots 1000 \
    --max_errors 10 \
    --processes auto \
    --save_resume_filepath "${SCRIPT_DIR}/stats.csv" \
    --metadata_func auto
