// Academic slide deck — Touying + Metropolis scaffold (typst-slides skill).
//
// Compile:
//   typst compile --ignore-system-fonts deck.typ
//
// --ignore-system-fonts keeps only typst's embedded fonts (Libertinus
// Serif, New Computer Modern Math, DejaVu Sans Mono), so the deck
// renders identically on every machine with zero font setup.
//
// Every example slide below is a pattern to copy, then delete what the
// deck doesn't need.

#import "@preview/touying:0.7.4": *
#import themes.metropolis: *

// Diagram toolkits — keep only what this deck uses.
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "@preview/cetz:0.5.2"
#import "@preview/lilaq:0.6.0" as lq
// #import "@preview/quill:0.7.3": *   // quantum circuits (QEC decks)

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,
  config-common(
    // Static deck: handout mode renders one page per slide even if a
    // #pause sneaks in, so the PDF never gains surprise build steps.
    handout: true,
    // Footnote-style citations: a plain `@key` in a slide renders as
    // [n] with the full reference at the bottom of that slide.
    show-bibliography-as-footnote: bibliography("refs.bib", title: none),
  ),
  config-info(
    title: [Deck Title],
    subtitle: [Optional subtitle],
    author: [Author Name],
    date: datetime.today(),
    institution: [Institution],
  ),
)

// Fonts: typst defaults on purpose (no #set text(font: ...)). The theme
// sets no family, so text uses Libertinus Serif, math New Computer
// Modern Math, raw DejaVu Sans Mono — all embedded in the typst binary.

#title-slide()

// `= Heading` starts a section (Metropolis renders a section slide);
// `== Heading` starts a normal slide; `---` starts an untitled slide.

= Outline <touying:hidden>
#outline(title: none, indent: 1em, depth: 1)

= Section Name

== Bullet slide — keep words minimal

- One idea per line, ≤ 2 lines per bullet
- Prefer a figure over a paragraph
- Claim needing support @vaswani2017

== Two-column slide

#slide(composer: (1fr, 1fr))[
  *Left:* short framing text

  - point
  - point
][
  #figure(
    diagram(
      node-stroke: 0.6pt,
      node-corner-radius: 3pt,
      spacing: (10mm, 8mm),
      node((0, 0), [Input]),
      edge("-|>"),
      node((1, 0), [Model]),
      edge("-|>"),
      node((2, 0), [Output]),
    ),
    caption: [Pipeline overview],
  )
]

== Figure slide (fletcher flowchart)

#figure(
  diagram(
    node-stroke: 0.6pt,
    node-corner-radius: 3pt,
    spacing: (14mm, 10mm),
    node((0, 0), [Data], fill: rgb("#eb811b").lighten(80%)),
    edge("-|>", [clean]),
    node((1, 0), [Features]),
    edge("-|>", [train]),
    node((2, 0), [Model]),
    edge("-|>", [eval]),
    node((3, 0), [Metrics]),
  ),
  caption: [Wide flowcharts: shrink `spacing` first, then wrap node text],
)

== Math slide

Attention weighs values by query–key similarity:

$ op("Attention")(Q, K, V) = op("softmax")((Q K^top) / sqrt(d_k)) V $

== Chart slide (lilaq)

#figure(
  lq.diagram(
    width: 14cm, height: 6cm,
    xlabel: [threads], ylabel: [throughput (Mops/s)],
    lq.plot((1, 2, 4, 8), (12.4, 24.1, 47.9, 96.5), label: [lock-free]),
    lq.plot((1, 2, 4, 8), (12.1, 18.0, 19.2, 18.9), label: [mutex]),
  ),
  caption: [In-typst charts via lilaq; use python + uv for complex ones],
)

== Table slide

#figure(
  table(
    columns: 3,
    stroke: (x, y) => if y == 0 { (bottom: 0.8pt) },
    table.header([Method], [Params], [Accuracy]),
    [Baseline], [12 M], [91.3 %],
    [Ours], [11 M], [*94.1 %*],
  ),
  caption: [Bold the number the audience should remember],
)

#focus-slide[
  One-line takeaway goes here
]

// References stay BEFORE #show: appendix — appendix slides keep
// advancing the page counter past the "N" in "n / N", so a references
// slide placed after it renders an ugly "9 / 8".
== References

#set text(size: 14pt)
#magic.bibliography(title: none)

// Backup slides: unnumbered, shown only if someone asks.
#show: appendix

= Backup <touying:hidden>

== Extra results

- Details cut from the main story live here
