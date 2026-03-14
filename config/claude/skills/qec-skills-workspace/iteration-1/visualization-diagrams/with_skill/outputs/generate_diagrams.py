#!/usr/bin/env python3
"""Generate surface code visualization diagrams using stim.

Produces three kinds of output for a rotated surface code circuit:
  1. Timeline SVG -- full circuit as a horizontal timeline
  2. Detector slice SVGs at ticks 0, 3, and 6 -- stabilizer configuration snapshots
  3. Crumble URL -- for interactive exploration in a browser
"""

from pathlib import Path

import stim

# ==============================================================================
# Output directory -- all artifacts land next to this script.
# ==============================================================================
OUTPUT_DIR = Path(__file__).resolve().parent


def main() -> None:
    # ------------------------------------------------------------------
    # Generate the circuit
    # ------------------------------------------------------------------
    # Distance-5 rotated surface code, 10 rounds of syndrome extraction,
    # with a small depolarizing noise model after every Clifford gate.
    circuit = stim.Circuit.generated(
        "surface_code:rotated_memory_z",
        distance=5,
        rounds=10,
        after_clifford_depolarization=0.001,
    )

    # Save the circuit itself so it can be reloaded or inspected later.
    circuit_path = OUTPUT_DIR / "surface_code_d5.stim"
    circuit_path.write_text(str(circuit))
    print(f"Circuit saved to {circuit_path}")

    # ------------------------------------------------------------------
    # 1. Timeline SVG -- overview of the full circuit
    # ------------------------------------------------------------------
    timeline_svg = circuit.diagram("timeline-svg")
    timeline_path = OUTPUT_DIR / "timeline.svg"
    timeline_path.write_text(str(timeline_svg))
    print(f"Timeline SVG saved to {timeline_path}")

    # ------------------------------------------------------------------
    # 2. Detector slice SVGs at ticks 0, 3, and 6
    # ------------------------------------------------------------------
    # Each tick shows the stabilizer configuration at that point in the
    # circuit, making it easy to see how detection regions evolve.
    for tick in (0, 3, 6):
        detslice_svg = circuit.diagram("detslice-svg", tick=tick)
        detslice_path = OUTPUT_DIR / f"detslice_tick{tick}.svg"
        detslice_path.write_text(str(detslice_svg))
        print(f"Detector slice SVG (tick {tick}) saved to {detslice_path}")

    # ------------------------------------------------------------------
    # 3. Crumble URL for interactive browser exploration
    # ------------------------------------------------------------------
    crumble_url = circuit.to_crumble_url()
    url_path = OUTPUT_DIR / "crumble_url.txt"
    url_path.write_text(crumble_url + "\n")
    print(f"\nCrumble URL saved to {url_path}")
    print(f"Open in browser: {crumble_url}")


if __name__ == "__main__":
    main()
