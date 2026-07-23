#!/usr/bin/env bash
# render-preview.sh — compile a deck to PDF + per-page PNGs for visual review.
#
# The PNGs are the point: after every content change, the pages must be
# looked at (with the Read tool) to catch overflow, overlap, and clipped
# diagrams that a successful compile does not reveal. Typst warnings are
# echoed because "unknown font family" means a silent fallback font — a
# layout bug in disguise.
#
# --ignore-system-fonts keeps only typst's embedded fonts (Libertinus
# Serif, New Computer Modern Math, DejaVu Sans Mono), so the deck
# renders identically on every machine with zero font setup.
#
# Usage:
#   render-preview.sh deck.typ [outdir]     # outdir defaults to tmp/preview
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: render-preview.sh <deck.typ> [outdir]" >&2
  exit 2
fi

DECK="$1"
OUTDIR="${2:-tmp/preview}"

mkdir -p "$OUTDIR"
rm -f "$OUTDIR"/page-*.png

base="$(basename "$DECK" .typ)"
pdf="$OUTDIR/$base.pdf"

# One compile for the deliverable PDF, one for the review PNGs.
typst compile --ignore-system-fonts "$DECK" "$pdf"
typst compile --ignore-system-fonts \
  --format png --ppi 96 "$DECK" "$OUTDIR/page-{0p}.png"

pages="$(find "$OUTDIR" -name 'page-*.png' | wc -l)"
echo "pdf   : $pdf"
echo "pages : $pages  ($OUTDIR/page-NN.png)"
echo "Now READ each page-NN.png and check: overflow, overlap, clipped"
echo "diagrams, unreadable labels, widowed content, wrong fonts."
