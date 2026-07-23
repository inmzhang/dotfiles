---
name: typst-slides
description: >
  Create academic presentation slides with Typst + Touying (Metropolis
  theme): hermetic typst-default fonts, cetz/fletcher diagrams, lilaq
  charts, verified footnote citations, and a mandatory visual
  page-by-page review loop. For quantum/QEC talks it adds quill circuit diagrams,
  stim-generated figures, and clickable Quirk links. Use this skill
  whenever the user asks for slides, a slide deck, a presentation, a
  talk, a seminar / journal-club / group-meeting / defense deck,
  beamer-style slides, or wants notes or a paper turned into a
  presentation — even if they never mention Typst. Also use it for any
  quantum-computing or quantum-error-correction presentation.
---

# Typst Slides (Touying + Metropolis)

Build clean, static, academic 16:9 slide decks. The stack is fixed so
every deck looks the same and compiles anywhere:

| Piece | Choice |
|---|---|
| Compiler | typst ≥ 0.14 |
| Framework | touying 0.7.4, Metropolis theme |
| Fonts | typst's embedded defaults (Libertinus Serif, New Computer Modern Math, DejaVu Sans Mono) — zero setup |
| Flowcharts / graphs | fletcher 0.5.8 |
| Freeform drawings | cetz 0.5.2 |
| Data charts | lilaq 0.6.0 (or cetz-plot 0.1.4); python via `uv` for anything complex |
| Quantum circuits | quill 0.7.3 + stim + Quirk links (see `references/quantum.md`) |
| Citations | footnote-style via touying, bibliography on final slide |

No animations: decks are fully static (`handout: true` is already set in
the template, which collapses any `#pause`/`#uncover` into one page).

## Step 0 — Get crystal clear on scope before writing any slide

A deck built on a fuzzy brief wastes everyone's time, so do not start
until scope and content structure are pinned down. If the `grilling`
skill is available, invoke it on the user's request. Otherwise
interrogate the user yourself (AskUserQuestion, one topic at a time)
until you can answer all of:

- **Audience & venue**: who is in the room, how much do they already know?
- **Duration & length**: N minutes → plan roughly one content slide per
  1.5–2 minutes. Push back on briefs that imply 40 slides for 15 minutes.
- **The one takeaway**: the single sentence the audience must remember
  (it becomes the `#focus-slide`).
- **Content outline**: sections and the story arc — motivation → idea →
  evidence → takeaway is the default skeleton.
- **Materials**: existing figures, data files, papers to cite, logos.
- **Citation expectations**: which claims need support.

Present the outline (sections + one-line per slide) and get sign-off
before writing Typst. Exception: when running unattended or the brief
already answers everything, proceed with the most reasonable choices and
list the assumptions you made alongside the deliverables.

## Step 1 — Project setup

```bash
mkdir -p figures tmp
cp <skill-dir>/assets/template.typ deck.typ
cp <skill-dir>/assets/refs.bib refs.bib
```

Compile with exactly:

```bash
typst compile --ignore-system-fonts deck.typ
```

`--ignore-system-fonts` is not optional pedantry: it restricts rendering
to the fonts embedded in the typst binary (Libertinus Serif, New
Computer Modern Math, DejaVu Sans Mono), which is what guarantees the
deck renders identically on the user's other machines with zero font
setup. Do not `#set text(font: ...)` — the defaults are the intended
look. The template
compiles as-is; build the deck by replacing its example slides — each
one is a known-good pattern (two-column, figure, math, chart, table,
focus, references, appendix). Keep generated figure files in `figures/`.

## Step 2 — Writing slides: words are the enemy

Slides support a spoken narrative; they are not the narrative.

- One idea per slide; one-line slide titles that state the point
  ("Sharding removes the lock bottleneck", not "Results").
- Bullets: ≤ 5 per slide, ≤ 2 lines each, fragments not sentences.
- Any relationship, pipeline, comparison, or trend: draw it (Step 3)
  instead of describing it. If a slide is > 40 % prose, redesign it.
- Numbers go in tables with the key number in `*bold*` (Metropolis
  renders strong text in accent orange).
- `#focus-slide[...]` for the takeaway; `= Section` slides to mark the
  story's chapters; backup material after `#show: appendix`.
- An outline slide is only worth it for talks with 3+ sections.

## Step 3 — Diagrams and charts

Read `references/diagrams.md` before drawing (exact APIs, sizing
recipes, version pitfalls). Selection rule:

- **fletcher** — flowcharts, architectures, anything nodes-and-arrows.
- **cetz** — freeform drawings (lattices, geometric schematics).
- **lilaq** — data charts from small/medium data pasted into the deck.
- **python via uv** (`uv run --with matplotlib,pandas python fig.py`) —
  large datasets, seaborn-style statistical plots, anything Typst-side
  tools do awkwardly. Save SVG into `figures/`, include with
  `#image("figures/x.svg")`. Keep the script in the project so figures
  are regenerable.

## Step 4 — Quantum / QEC decks

Read `references/quantum.md`. In short: quill draws circuits, stim
generates circuit/detector SVGs and timelines for QEC constructions, and
every non-trivial circuit gets a clickable **Quirk** link so the
audience can explore it interactively.

## Step 5 — Citations

The template already wires footnote-style citations: write `@key` in a
slide and the full reference appears as a footnote on that slide, plus
in the final References slide. Add entries to `refs.bib`.

Every entry must be verified before delivery — a hallucinated citation
on a projected slide is a credibility disaster. Follow
`references/citations.md`: verify title/authors/year/venue against
arXiv/DOI/Crossref with curl, and record how each entry was checked.

## Step 6 — Visual verification loop (mandatory, never skip)

A clean compile proves nothing about layout. After every substantive
change:

```bash
bash <skill-dir>/scripts/render-preview.sh deck.typ tmp/preview
```

Then **Read every `tmp/preview/page-NN.png`** and inspect against this
checklist:

- Text or figures overflowing the slide edge, or colliding with the
  header bar / footer / footnote block.
- Diagrams: every node label readable, every arrow visible and attached
  to the right box, edge labels not overlapping nodes; wide flowcharts
  shrunk to fit (sizing recipes in `references/diagrams.md`).
- Charts: axis labels present, legend not covering data.
- Fonts: any typst "unknown font family" warning means a silent
  fallback — fix the font name, don't ignore it.
- Slide numbering sane (references slide before `#show: appendix`,
  otherwise the counter renders "9 / 8").
- Widows: a slide with one lonely bullet or a caption split from its
  figure means content should merge with a neighbor.

Fix, re-render, re-read. Two clean consecutive passes = done. Deliver
the PDF, `deck.typ`, `refs.bib`, `figures/` + generator scripts, and the
list of assumptions made in Step 0.
