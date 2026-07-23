# Diagrams & charts — fletcher / cetz / lilaq / external tools

All snippets verified on typst 0.14.2 with the pinned versions below.
Training-data-era code for these packages often fails — check the
pitfalls section before pattern-matching from memory.

## Imports (pinned)

```typst
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4": plot, chart
#import "@preview/lilaq:0.6.0" as lq
```

fletcher 0.5.8 bundles its own cetz 0.3.4 internally — co-importing
cetz 0.5.2 for your own drawings is safe (they're separate module
instances), but don't pass cetz-0.5.2 objects into fletcher hooks.

## fletcher — flowcharts & architectures

Coordinates are `(col, row)`, row grows downward. `edge("-|>")` with no
coordinates auto-connects the surrounding nodes.

```typst
#diagram(
  node-stroke: 0.6pt, node-corner-radius: 3pt,
  node-inset: 6pt,                // padding inside nodes
  spacing: (12mm, 8mm),           // (col, row) gutters — first knob for width
  node((0, 0), [Ingest], fill: rgb("#eb811b").lighten(80%)),
  edge("-|>", [tokens]),          // labeled arrow
  node((1, 0), [Parse]),
  edge((1, 0), (2, 0), "-|>"),    // explicit endpoints
  node((2, 0), [Check], shape: fletcher.shapes.diamond),
  edge((2, 0), (2, 1), "--|>", [no]),      // "--" prefix = dashed
  node((2, 1), [Retry]),
  edge((2, 1), (1, 0), "-|>", bend: 30deg),
)
```

- Marks: `"->"`, `"-|>"` (nicer solid head), `"<->"`, `"=>"`, `"-->"`,
  `"hook->"`. Shapes: `fletcher.shapes.{rect,circle,ellipse,pill,
  diamond,hexagon,parallelogram,trapezium,house,octagon}`.
- Edge labels: positional content arg; `label-side: center` puts the
  label ON the edge with a background; add `label-sep: 2pt` if a label
  crowds a node border.
- Multi-vertex edges: `edge("r,u,r", "=>")`.

### Fitting wide diagrams on a 16:9 slide

Shrink in this order: (1) `spacing`, (2) shorter node labels /
wrapped text via `node((..), [Two\ lines])`, (3) scale as a last resort:

```typst
// fixed scale — reflow: true makes layout use the scaled size
#figure(scale(70%, reflow: true, wide-diagram), caption: [...])

// auto fit-to-width (shrink only, never enlarges)
#let fit-width(body) = layout(sz => {
  let m = measure(body)
  let s = calc.min(1.0, sz.width / m.width)
  scale(s * 100%, reflow: true, body)
})
#figure(fit-width(wide-diagram), caption: [...])
```

After scaling, re-render and confirm labels are still readable (≥ ~12pt
effective). If not, the diagram has too much in it — split it.

## cetz — freeform drawings

```typst
#cetz.canvas({
  import cetz.draw: *
  rect((0, 0), (2, 1), fill: blue.lighten(80%), stroke: blue, radius: 2pt)
  circle((4, 0.5), radius: 0.6)
  line((2, 0.5), (3.4, 0.5), mark: (end: ">"))
  content((1, 0.5), [Box])
})
```

Good for lattices/grids (QEC layouts), geometric schematics, annotated
coordinate drawings. Compass anchors use TikZ names (`north`, not `top`).

## Charts

**lilaq** (preferred — clean grammar, good defaults):

```typst
#lq.diagram(
  width: 14cm, height: 6cm,
  xlabel: [threads], ylabel: [throughput (Mops/s)],
  lq.plot((1, 2, 4, 8), (12.4, 24.1, 47.9, 96.5), label: [lock-free]),
  lq.bar((1, 2, 3), (5.2, 7.9, 3.1)),   // bar series
)
```

**cetz-plot** (alternative; note it is a SEPARATE package — `cetz.plot`
was removed from cetz core in 0.3.0):

```typst
#cetz.canvas({
  plot.plot(size: (8, 5), x-label: [$x$],
    { plot.add(domain: (0, 3), x => 2 * x, label: [$2x$]) })
})
```

**External tools** — when data is large, statistical, or needs
matplotlib/seaborn/plotly-grade rendering:

```bash
uv run --with matplotlib,pandas python figures/make_scaling.py
```

Script requirements: read data from file (not hard-coded), write SVG
(`plt.savefig("figures/scaling.svg")`, `svg.fonttype: "none"` optional),
font sizes ≥ 14pt so they survive slide scaling. Include with
`#figure(image("figures/scaling.svg", width: 80%), caption: [...])`.
Node/JS tools (mermaid-cli, d3 via a script) are fine too when they fit
better — same rule: emit SVG into `figures/`, keep the script.

## Version pitfalls (why memory-written code fails)

- `cetz.plot` / `cetz.chart` gone since cetz 0.3.0 → use `cetz-plot`.
- cetz ≥ 0.3: compass anchors renamed (`top`→`north`), right-handed
  coords, CCW rotation, new mark syntax. cetz 0.5: `on-yz` → `on-zy`.
- fletcher < 0.4 had no auto-edges; 0.5 rewrote marks and added
  `enclose`/`layer`/multi-vertex edges.
- quill: `targX()` removed in 0.6 (use `swap`), `color:` param removed
  in 0.7.3 (see `references/quantum.md`).
