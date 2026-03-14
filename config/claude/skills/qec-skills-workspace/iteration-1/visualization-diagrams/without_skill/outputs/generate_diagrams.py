#!/usr/bin/env python3
"""Generate visualization diagrams for a rotated surface code circuit.

Produces:
  1. A timeline SVG diagram of the full circuit.
  2. Detector slice SVG diagrams at ticks 0, 3, and 6.
  3. A Crumble URL for interactive browser-based editing.

Usage:
    uv run --with stim python generate_diagrams.py
"""

from pathlib import Path

import stim

# All outputs go alongside this script.
OUTPUT_DIR = Path(__file__).resolve().parent


def main() -> None:
    # ── Generate the test circuit ─────────────────────────────────────────
    circuit = stim.Circuit.generated(
        "surface_code:rotated_memory_z",
        distance=5,
        rounds=10,
        after_clifford_depolarization=0.001,
    )

    circuit_path = OUTPUT_DIR / "surface_code_d5_r10.stim"
    circuit.to_file(str(circuit_path))
    print(f"Circuit saved to {circuit_path}")

    # ── 1. Timeline SVG ──────────────────────────────────────────────────
    timeline_svg = circuit.diagram("timeline-svg")
    timeline_path = OUTPUT_DIR / "timeline.svg"
    timeline_path.write_text(str(timeline_svg))
    print(f"Timeline SVG saved to {timeline_path}")

    # ── 2. Detector slice SVGs at ticks 0, 3, and 6 ─────────────────────
    for tick in [0, 3, 6]:
        detslice_svg = circuit.diagram("detslice-svg", tick=tick)
        detslice_path = OUTPUT_DIR / f"detslice_tick{tick}.svg"
        detslice_path.write_text(str(detslice_svg))
        print(f"Detector slice SVG (tick {tick}) saved to {detslice_path}")

    # ── 3. Crumble URL ──────────────────────────────────────────────────
    crumble_url = circuit.to_crumble_url()
    url_path = OUTPUT_DIR / "crumble_url.txt"
    url_path.write_text(crumble_url + "\n")
    print(f"\nCrumble URL saved to {url_path}")
    print(f"Crumble URL: {crumble_url[:120]}...")


if __name__ == "__main__":
    main()
