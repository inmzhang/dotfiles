---
name: qec-visualization
description: >
  Visualize QEC circuits using stim diagrams and crumble interactive editor.
  Use this skill when the user wants to generate circuit diagrams (timeline-svg,
  detslice-svg, detslice-with-ops-svg, matchgraph, timeslice), open circuits
  in crumble, add polygon annotations for stabilizer regions, use crumble
  keybindings for interactive editing, share circuit links, export circuit SVGs,
  or visualize detector error models. Also trigger when the user mentions
  circuit visualization, Pauli propagation visualization, detection region
  diagrams, or wants to see what a QEC circuit looks like.
---

# QEC Circuit Visualization

This skill covers generating diagrams with stim's `diagram()` API and using
crumble's interactive web editor for circuit exploration and annotation.

## Environment Setup

```bash
# For generating diagrams programmatically
uv run --with stim python generate_diagrams.py

# For stim CLI diagrams
uv run --with stim stim diagram --type timeline-svg --in circuit.stim > timeline.svg
```

## Stim Diagram Types

### Overview of Available Types

| Type | Description | Best for |
|------|-------------|----------|
| `timeline-svg` | Full circuit as horizontal timeline | Understanding gate ordering |
| `timeline-text` | ASCII circuit diagram | Quick terminal inspection |
| `detslice-svg` | Detector stabilizers at a specific tick | Seeing stabilizer configuration |
| `detslice-with-ops-svg` | Detector slice + operations | Seeing stabilizers with gates |
| `timeslice-svg` | Operations between ticks | Seeing one layer of operations |
| `matchgraph-svg` | Matching graph from DEM | Decoder graph structure |
| `interactive` | Opens crumble editor | Interactive exploration |

### Generating Diagrams with Python API

```python
import stim

circuit = stim.Circuit.from_file("my_circuit.stim")

# Timeline diagram (most commonly used)
svg = circuit.diagram("timeline-svg")
with open("timeline.svg", "w") as f:
    f.write(str(svg))

# Detector slice at a specific tick
svg = circuit.diagram("detslice-svg", tick=3)

# Detector slice over a range of ticks
svg = circuit.diagram("detslice-svg", tick=range(0, 5))

# Detector slice with operations overlaid
svg = circuit.diagram("detslice-with-ops-svg", tick=3)

# Filter by coordinate region (useful for large circuits)
svg = circuit.diagram("detslice-svg", tick=3, filter_coords=[(0, 0, 5, 5)])

# Matching graph
svg = circuit.diagram("matchgraph-svg")

# Interactive HTML (crumble)
html = circuit.diagram("interactive")
with open("crumble.html", "w") as f:
    f.write(str(html))
```

### Generating Diagrams with CLI

```bash
# Timeline SVG
stim diagram --type timeline-svg --in circuit.stim > timeline.svg

# Detector slice at tick 3
stim diagram --type detslice-svg --tick 3 --in circuit.stim > detslice.svg

# Detector slice with operations
stim diagram --type detslice-with-ops-svg --tick 3 --in circuit.stim > detslice_ops.svg

# Matching graph
stim diagram --type matchgraph-svg --in circuit.stim > matchgraph.svg

# ASCII timeline (for terminal)
stim diagram --type timeline-text --in circuit.stim
```

### HTML Variants

Most SVG types have an `-html` variant that wraps the SVG in a standalone
HTML page with pan/zoom controls:

```python
html = circuit.diagram("timeline-svg-html")
html = circuit.diagram("detslice-svg-html")
html = circuit.diagram("matchgraph-svg-html")
```

### 3D Variants

For spatial codes, 3D diagrams show the spacetime structure:

```python
html = circuit.diagram("timeline-3d-html")
html = circuit.diagram("matchgraph-3d-html")
```

## Crumble Interactive Editor

Crumble is a web-based circuit editor with automatic Pauli propagation
visualization. It is the primary tool for interactive circuit design and
debugging.

### Opening a Circuit in Crumble

```python
# Generate a crumble URL from a circuit
url = circuit.to_crumble_url()
# Opens: https://algassert.com/crumble#circuit=...

# Or generate an interactive HTML file
html = circuit.diagram("interactive")
with open("crumble.html", "w") as f:
    f.write(str(html))
# Then open crumble.html in a browser
```

### Circuit Import/Export in Crumble

- Click "Show Import/Export" button to reveal the circuit text area
- Paste a stim circuit string to import
- Copy the text to export the current circuit
- The circuit is also encoded in the URL fragment (`#circuit=...`), so
  bookmarking preserves the circuit state

### Crumble Keyboard Reference

#### Gate Placement

| Key | Gate | Notes |
|-----|------|-------|
| `h` | H | Hadamard |
| `s` | S | Phase gate (shift+s for S_DAG) |
| `r` | R | Z-basis reset |
| `r+x` | RX | X-basis reset |
| `r+y` | RY | Y-basis reset |
| `m` | M | Z-basis measurement |
| `m+x` | MX | X-basis measurement |
| `m+y` | MY | Y-basis measurement |
| `m+r` | MR | Measure+reset (Z) |
| `m+r+x` | MRX | Measure+reset (X) |
| `c+x` | CX | CNOT (hover second qubit) |
| `c+y` | CY | Controlled-Y |
| `c+z` | CZ | Controlled-Z |
| `w` | SWAP | Swap gate |
| `w+i` | ISWAP | iSWAP gate |
| `m+p+x` | MPP(X...) | Multi-Pauli product measurement |
| `m+p+z` | MPP(Z...) | Multi-Pauli product measurement |

Use `shift` with gate keys for inverse variants (e.g., shift+s for S_DAG).

#### Pauli Markers (Flow Tracking)

Pauli markers are the core visualization tool. Place them to track how Pauli
operators propagate through the circuit, which reveals stabilizer flows.

| Key | Action |
|-----|--------|
| `space` | Clear all markers at selection |
| `1`-`9` | Place marker with index 1-9 (basis inferred from context) |
| `x+1` | Place X marker with index 1 |
| `y+2` | Place Y marker with index 2 |
| `z+3` | Place Z marker with index 3 |
| `d+1` | Convert marker 1 into a DETECTOR declaration |
| `o+1` | Convert marker 1 into an OBSERVABLE_INCLUDE |
| `k+1` | Mark dissipative gates overlapping with tracked product |

**Workflow for annotating detectors:**
1. Place a marker after a reset (e.g., `z+1` after RZ on ancilla qubit)
2. Navigate forward through the circuit with `e` to see the Pauli propagate
3. At the measurement point, the marker should collapse
4. Press `d+1` to convert the tracked marker into a DETECTOR instruction

#### Navigation

| Key | Action |
|-----|--------|
| `q` | Previous time layer |
| `e` | Next time layer |
| `shift+q` | Jump 5 layers back |
| `shift+e` | Jump 5 layers forward |
| `home` | First layer |
| `end` | Last layer |
| `ctrl+z` | Undo |
| `ctrl+y` | Redo |

#### Annotations

| Key | Action |
|-----|--------|
| `p` | Create polygon annotation (background region) |
| `p+x` | Red polygon (for X stabilizers) |
| `p+z` | Blue polygon (for Z stabilizers) |
| `p+y` | Green polygon (for Y stabilizers) |
| `p+shift` | Darker variant |
| `p+alt` | Lighter variant |

Polygons are purely visual — they highlight stabilizer regions in the circuit
so you can easily see which operations belong to which stabilizer.

#### Coordinate Transformations

| Key | Action |
|-----|--------|
| `t` | Rotate 45 degrees clockwise |
| `shift+t` | Rotate 45 degrees counter-clockwise |
| `v` | Translate down |
| `^` | Translate up |
| `>` | Translate right |
| `<` | Translate left |
| `.` | Translate down-right (half step) |

#### Batch Operations

| Key | Action |
|-----|--------|
| `ctrl+c` | Copy selection or entire layer |
| `ctrl+v` | Paste |
| `ctrl+x` | Cut |
| `ctrl+delete` | Delete current layer |
| `f` | Reverse direction of two-qubit gates |
| `g` | Reverse layer order |

## Detecting Regions Visualization

Beyond static diagrams, you can programmatically query where each detector
is sensitive to errors:

```python
regions = circuit.detecting_regions(
    targets=["D5", "L0"],  # specific detectors/observables
    ticks=range(0, 10),    # time range to query
)
# Returns dict[DemTarget, dict[int, PauliString]]
# Shows which Pauli errors at each tick affect each detector
```

## Visualization Workflow

### For Circuit Design (with Crumble)

1. Start with a small circuit in crumble (few qubits, one stabilizer)
2. Place Pauli markers after resets to track stabilizer flow
3. Step through with `e` to see propagation
4. Add polygon annotations to highlight stabilizer regions
5. Convert markers to detectors with `d+N`
6. Export the circuit and verify programmatically

### For Publication Figures

1. Generate `detslice-svg` diagrams at key time steps
2. Add polygon annotations in crumble for stabilizer coloring
3. Use `timeline-svg` for full circuit overview
4. Save as SVG for vector graphics in papers

### For Debugging

1. Use `detslice-with-ops-svg` to see stabilizer structure + operations
2. Use `matchgraph-svg` to visualize the decoder's view of errors
3. Open in crumble and place markers to trace suspicious error paths
4. Check `detecting_regions()` to verify detector sensitivity
