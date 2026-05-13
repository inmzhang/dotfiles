#let paper-title = "Paper Title"
#let paper-authors = "Author list"
#let source-link = "https://arxiv.org/abs/0000.00000"
#let prepared-by = "Your Name"
#let prepared-on = "YYYY-MM-DD"

#set document(title: paper-title, author: prepared-by)
#set page(
  paper: "us-letter",
  margin: (top: 0.85in, bottom: 0.9in, x: 0.9in),
  numbering: "1",
)
#set text(font: ("Libertinus Serif", "New Computer Modern"), size: 10pt)
#set par(justify: true)
#set heading(numbering: "1.")

#align(center)[
  #text(size: 22pt, weight: "bold")[#paper-title]
  #v(0.35em)
  #text(size: 11pt, fill: rgb("#555555"))[#paper-authors]
  #v(0.25em)
  #text(size: 9pt, fill: rgb("#666666"))[
    Source: #link(source-link)[#source-link]
  ]
  #v(0.15em)
  #text(size: 9pt, fill: rgb("#666666"))[
    Prepared by #prepared-by on #prepared-on
  ]
]

#v(1.2em)

*One-sentence takeaway.* Replace this with the clearest grounded summary of the paper.

= Focus Area And Claim

What area does the paper address, what is the main research question, and what is the central claim?

= Background Needed For Context

Inline only the background needed to understand the difficult parts of the paper.

= Methodology

Explain the core idea, model, construction, algorithm, proof strategy, or experimental design in technical detail.

= Innovation

What is new relative to prior work? Distinguish new contributions from engineering choices, presentation, or recombination of known ideas.

= Evidence

Summarize the experiments, theorems, simulations, or benchmarks that support the claim.

= Key Numbers

- Main metric:
- Baseline comparison:
- Data, compute, implementation, or theoretical assumptions:

= Limitations

- Important caveat:
- Missing comparison:
- Assumption that could break in practice:

= Open Problems And Future Directions

- Open technical question:
- Scalability or robustness concern:
- Future direction suggested by the paper:
- Additional future direction inferred from the evidence:

= Q&A

Add user review questions and answers here after the first report draft is complete.
