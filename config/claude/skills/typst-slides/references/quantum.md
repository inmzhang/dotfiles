# Quantum / QEC slides — quill, stim, Quirk

Verified on typst 0.14.2 (quill 0.7.3) and stim ≥ 1.13 via uv.

## quill — drawing quantum circuits in Typst

```typst
#import "@preview/quill:0.7.3": *

// Bell pair: [\ ] ends a wire row; bare integer n = n empty cells.
#quantum-circuit(
  lstick($|0〉$), gate($H$), ctrl(1), meter(), [\ ],
  lstick($|0〉$), 1, targ(), meter(),
)
```

- `ctrl(k)`: control dot with vertical wire k rows down (negative = up);
  pair with `targ()` (CNOT), `ctrl(0)` (CZ endpoint), or a `gate(..)`.
- `mqgate($U$, n: 3)`: gate spanning 3 wires. `meter()` measurement,
  `lstick`/`rstick` for kets and labels, `swap(k)` for swaps.
- Kets: use `〉` (U+3009) or define `#let ket(x) = $lr(|#x angle.r)$` —
  LaTeX `\rangle` does not exist in typst.
- Sizing: `quantum-circuit(scale: 80%, ...)` is built in; also
  `row-spacing`/`column-spacing`. Group logical blocks with
  `gategroup(x: .., y: .., cols, rows)`.
- Programmatic building (loops over qubits — right choice for syndrome
  extraction circuits):

```typst
#import "@preview/quill:0.7.3": tequila as tq
#quantum-circuit(
  ..tq.build(tq.h(0), tq.cx(0, 1), tq.cx(0, 2)),
)
```

Pitfalls: `targX()` died in quill 0.6 (use `swap`), `color:` parameter
died in 0.7.3.

## stim — generated circuits and SVG figures

Run stim through uv; never hand-write a surface-code circuit when
`stim.Circuit.generated` produces a canonical one:

```bash
uv run --with stim python figures/make_qec.py
```

```python
import stim

c = stim.Circuit.generated(
    "surface_code:rotated_memory_z", distance=3, rounds=2)

# Timeline (gate sequence) — good for "how syndrome extraction works":
with open("figures/timeline.svg", "w") as f:
    f.write(str(c.diagram("timeline-svg")))

# Detector-slice with operations — the classic QEC lattice-with-CNOTs
# figure; pick ticks covering one syndrome-extraction round:
with open("figures/detslice.svg", "w") as f:
    f.write(str(c.diagram("detslice-with-ops-svg", tick=range(0, 8))))
```

Embed: `#figure(image("figures/detslice.svg", height: 10cm), ...)`.
stim SVGs are wide — set `height:` not `width:`, render, and check
label legibility. Other useful diagram types: `"timeslice-svg"`,
`"match-graph-svg"`, `"detslice-svg"`.

## Quirk — interactive links for ANY quantum circuit

Quirk (`algassert.com/quirk`) is a general drag-and-drop quantum
circuit simulator with live amplitude/Bloch displays — not a stim/QEC
tool. Any circuit drawn with quill in the deck (VQE ansatz,
teleportation, Grover iteration, a stabilizer gadget, …) should carry a
clickable Quirk link so the presenter can run it live.

The whole circuit is encoded in the URL fragment as JSON: an array of
columns, each column an array of per-wire entries top-to-bottom.
`1` = identity, `"•"` = control (literal bullet). Common gate ids:
`"H" "X" "Y" "Z" "S" "T" "X^½" "Z^¼" "Swap" "Measure"`.

```
https://algassert.com/quirk#circuit={"cols":[["H"],["•","X"],["Measure","Measure"]]}
```

Build URLs with a few lines of python (no dependencies):

```python
import json, urllib.parse
cols = [["H"], ["•", "X"], ["Measure", "Measure"]]   # Bell pair
frag = json.dumps({"cols": cols}, separators=(",", ":"), ensure_ascii=False)
# Percent-encode: the raw "•" control char gets mojibake'd inside PDF
# link annotations in some viewers; Quirk's own share URLs encode too.
url = "https://algassert.com/quirk#circuit=" + urllib.parse.quote(frag, safe="")
open("figures/quirk_url.txt", "w").write(url)
```

Convenience: if the circuit already exists as a `stim.Circuit`,
`c.to_quirk_url()` does the conversion in one call.

Limit: **Quirk simulates full state vectors and caps at 16 qubits.**
Link gadget-sized circuits — one stabilizer measurement, an encoder, a
teleportation — which is also the pedagogically right granularity. For
a construction too big to load (a full d=3 QEC round needs 17+ qubits),
link the Quirk gadget that repeats, not the whole thing.

In the deck:

```typst
#link(read("figures/quirk_url.txt").trim())[
  #text(fill: rgb("#eb811b"))[⤷ explore this circuit in Quirk]
]
```

(Read the URL from a file rather than pasting a long URL into the .typ
source.) Verify before delivery: `curl -sI https://algassert.com/quirk`
→ 200, and eyeball that the JSON columns match the quill figure
gate-for-gate — the two are drawn from the same source of truth, so a
mismatch means one of them is wrong.

## Slide-design notes for QEC talks

- One circuit per slide; a d=3 syndrome round already fills a slide.
- Prefer the detslice figure for "what the code looks like" and quill
  for "what one stabilizer measurement does" — stim exports carry too
  much detail for an intro slide, quill stays readable.
- Cite the canonical papers (Kitaev 2003, Fowler et al. 2012, and the
  specific decoder/experiment under discussion) with `@key` footnotes.
