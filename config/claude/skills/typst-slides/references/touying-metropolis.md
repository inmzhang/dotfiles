# Touying 0.7.4 + Metropolis — API reference

Everything here was verified against touying 0.7.4 on typst 0.14.2.

## Skeleton

```typst
#import "@preview/touying:0.7.4": *
#import themes.metropolis: *

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,   // default footer is none
  config-common(
    handout: true,                          // static deck: collapse #pause etc.
    show-bibliography-as-footnote: bibliography("refs.bib", title: none),
  ),
  config-info(
    title: [Title], subtitle: [Sub], author: [A. Author],
    date: datetime.today(), institution: [Inst],
    logo: image("logo.svg", height: 1.2em),   // rendered top-right of slides
  ),
)

// Fonts: deliberately NO #set text(font: ...). The theme sets no font
// family, so typst's embedded defaults apply — Libertinus Serif (text),
// New Computer Modern Math (math), DejaVu Sans Mono (raw). Combined
// with `typst compile --ignore-system-fonts` this renders identically
// everywhere with zero setup. If a user insists on another font, set it
// AFTER the show rule and warn them it must exist on every machine
// that compiles the deck.
```

## Headings → slides

- `= X` → section slide (big centered title + progress line)
- `== X` → normal slide titled X
- `---` → untitled slide in the current section
- Heading labels: `<touying:hidden>` (slide but heading text hidden),
  `<touying:skip>` (no section slide), `<touying:unnumbered>`,
  `<touying:unoutlined>`, `<touying:handout>` (handout-only slide).
- Outline slide: `= Outline <touying:hidden>` then
  `#outline(title: none, indent: 1em, depth: 1)`.

## Useful config

```typst
config-common(
  handout: true,               // last subslide only → fully static
  slide-level: 2,              // default; 3 makes === slides
  datetime-format: "[year]-[month]-[day]",
  show-notes-on-second-screen: right,   // speaker notes (pympress)
)
config-colors(                  // metropolis defaults shown
  primary: rgb("#eb811b"),      // orange: alerts, progress bar
  secondary: rgb("#23373b"),    // dark teal: header bar
  neutral-lightest: rgb("#fafafa"),  // background
  neutral-darkest: rgb("#23373b"),   // body text
)
```

Theme defaults: slide counter `n / N` bottom-right, thin orange progress
bar at bottom (`footer-progress: false` kills it), margins
`(top: 3em, bottom: 1.5em, x: 2em)`.

## Slides & layout

```typst
// Two columns (composer defaults to equal columns, 1em gutter):
#slide(composer: (1fr, 1fr))[ left ][ right ]
#slide(composer: (2fr, 1fr))[ wide left ][ narrow right ]

#focus-slide[ One-line takeaway ]        // dark full-bleed slide
#speaker-note[ ... ]                     // attaches to slide ABOVE (0.7.3+)

#show: appendix                          // slides after: unnumbered backup
```

Plain `#grid` inside a slide works too. `#align(center)` a lone figure.

## Citations

With `show-bibliography-as-footnote` configured (see skeleton), a plain
`@key` renders as `[n]` with the full reference as a footnote on that
slide. Final slide:

```typst
== References
#set text(size: 14pt)
#magic.bibliography(title: none)
```

Keep the References slide BEFORE `#show: appendix` — appendix slides
keep advancing the page counter past N, rendering "9 / 8".

Alternative without touying's mechanism: `#set cite(style:
"chicago-notes")` + `#bibliography(...)`, or ad-hoc
`#footnote(cite(<key>, form: "full"))`. Never use a blanket
`#show cite: it => footnote(it)` (recursion artifacts).

## Gotchas

- Touying 0.7.x needs typst ≥ 0.12; the 0.14 bibliography crash
  (touying#229) was fixed in 0.6.2 — pin 0.7.4 and it's a non-issue.
- `#pause`/`#meanwhile`/`#uncover`/`#only` all still compile with
  `handout: true` — they just render on one page. Don't use them in new
  content; static decks shouldn't need them.
- `title-slide()` must be called explicitly after the show rule.
