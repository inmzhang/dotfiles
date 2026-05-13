# Analysis Checklist

## Reading Pass

- Identify the exact task: summarize, deeply analyze, compare, or produce repo outputs.
- Record the paper title, authors, venue/status, and source link.
- Capture the paper's focus area, stated problem, main idea, and headline empirical or theoretical claim.
- Identify the intended audience and the prior-work context the paper assumes.
- Distinguish what the paper proves, what it measures, and what it only suggests.

## Claim And Contribution

- State the central claim in one precise sentence.
- List secondary claims separately, with their supporting evidence.
- Explain the novelty relative to prior work: new problem framing, method, theory, system, data, benchmark, or synthesis.
- Mark claims that depend on narrow assumptions, limited regimes, untested generalization, or omitted baselines.

## Methodology

- Explain the core mechanism, model, algorithm, construction, proof strategy, or experimental design.
- Define important notation, variables, objectives, metrics, and assumptions before relying on them.
- Trace the method step by step when the paper's contribution depends on a pipeline or derivation.
- Include background inline for difficult concepts when it is required to understand the paper's argument.
- Note implementation details, datasets, preprocessing, experimental settings, or theoretical conditions that materially affect the result.

## Evidence Extraction

- Tie every major claim to a section, figure, table, theorem, or appendix item.
- Note the evaluation setting: datasets, simulators, hardware assumptions, baselines, and ablations.
- Check whether confidence intervals, error bars, or sensitivity studies exist.
- Separate the authors' framing from the actual measured evidence.

## Open Problems And Future Directions

- Extract limitations explicitly acknowledged by the authors.
- Add limitations implied by the evidence, assumptions, or missing comparisons.
- Identify unresolved technical questions, scalability concerns, robustness gaps, and reproducibility risks.
- Separate future work proposed by the paper from your own inferred future directions.

## Report Quality Bar

- Lead with the one-sentence takeaway and the paper's scope.
- Explain focus area, claim, methodology, innovation, evidence, limitations, open problems, and future directions.
- Preserve technical detail when it is necessary for understanding; compress only incidental setup.
- Use precise language for uncertainty: "claims", "reports", "simulates", "proves", "suggests".
- Prefer short tables or bullets for metrics, baselines, and caveats when they help scanning.
- End with the most decision-relevant caveats, open problems, or future directions.

## Validation

- Compile `report.typ`.
- Re-read the abstract, conclusion, and the figures you cited after drafting.
- Check that filenames match repo conventions: `paper.pdf`, `report.typ`, `report.pdf`.
