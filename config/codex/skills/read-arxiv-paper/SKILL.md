---
name: read-arxiv-paper
description: "Use when asked to read, summarize, analyze, critique, or package an arXiv paper or local scientific paper into a comprehensive Typst report in this repository."
---

# Read Arxiv Paper

Use this skill to run the full paper workflow for this repository: intake the paper, build a faithful technical reading, ship a polished Typst report, then support the user's review questions.

## Workflow

1. Create a repo-root paper directory with a concise kebab-case slug.
2. Populate the canonical inputs:
   - `paper.pdf`
   - `paper-source.tar.gz` when source is available
   - `source/` with extracted TeX or source files
3. Read the paper and keep notes tied to evidence.
4. Draft `report.typ`.
5. Compile `report.pdf`.
6. Ask the user to read the written report.
7. Enter the review Q&A loop:
   - Ask the user to either ask a question about the paper/report or say they are finished.
   - If they ask a question, answer using the paper content first, then relevant outside knowledge when it helps. Be explicit when adding interpretation beyond the paper.
   - Add the question and answer to a `Q&A` section in `report.typ`.
   - Recompile `report.pdf`.
   - Repeat until the user says they are finished.

## Intake

For arXiv papers, prefer the bundled downloader instead of rewriting the workflow in the prompt. It folds the old `download.md` instructions into the repo-local layout.

```bash
rtk python /home/inm/dotfiles/config/codex/skills/read-arxiv-paper/scripts/fetch_arxiv.py \
  https://arxiv.org/abs/2601.07372 \
  --paper-dir ./my-paper-slug
```

The script:

- normalizes `abs`, `pdf`, or `src` URLs to the arXiv id
- downloads `paper.pdf`
- downloads `paper-source.tar.gz`
- extracts the source into `source/`
- searches for the likely LaTeX entrypoint
- writes `paper-meta.json` with the resolved paths

If the user provides a local PDF instead of an arXiv link, place it at `paper.pdf` and continue without the downloader.

## Reading Standard

- Clarify the paper's main focus area, research question, and intended contribution.
- Identify the central claim and distinguish it from secondary claims, hypotheses, and motivation.
- Explain the methodology in enough technical detail that a reader can understand the mechanism, assumptions, and evaluation design without reading the original first.
- Surface the innovation: what is new relative to prior work, what is combined in a new way, and what is merely implementation or presentation.
- Tie strong claims to concrete evidence: theorem, equation, figure, table, appendix, dataset, benchmark, proof, or experiment.
- Separate what the paper demonstrates from what it speculates, and label your own interpretation as interpretation.
- Identify open problems, limitations, and future directions, including cases where the paper leaves an assumption, metric, proof gap, or empirical question unresolved.
- Inline background only when it is needed for full context on a difficult point; keep it concise and connected to the paper's argument.
- Prefer exact terminology and careful academic phrasing over hype.

Read [references/analysis-checklist.md](references/analysis-checklist.md) when you need the detailed extraction checklist.

## Output Files

Use the bundled templates as starting points when you need a fast, consistent structure:

- [assets/report-template.typ](assets/report-template.typ)

For the actual Typst authoring work, use the `typst` skill for document writing, layout, and syntax.

## User Review Loop

After the first complete report has compiled, do not treat the paper-reading phase as finished until the user has had a chance to review it. Tell the user where the report is, ask them to read it, and invite one question at a time or a clear finish signal.

For each question:

- Answer directly in chat, grounded in the paper. Cite section, theorem, figure, table, or equation numbers when useful.
- If using knowledge beyond the paper, label it as context or interpretation.
- Append the exchange to `report.typ` under `= Q&A`. Create the section if it does not exist.
- Keep recorded answers polished enough to be useful later, but concise enough that the report remains readable.
- Run `rtk typst compile report.typ report.pdf` after each report update.

The loop ends only when the user says they are finished, done, has no more questions, or otherwise clearly declines further questions.

## Quality Bar

- Keep the report comprehensive, polished, readable, and grounded in the source.
- Do not skip technical details that are necessary to understand the claim, method, evidence, or limitations.
- Write in a concise academic style: dense enough for technical readers, but with enough inline context to make difficult ideas understandable.
- Use compact tables or bullets when they improve scanability.
- End with the sharpest limitations, open problems, and future directions instead of a generic conclusion.
- Record user follow-up Q&A faithfully, while correcting misconceptions in the answer instead of preserving them unchallenged.

## Validation

- Run `rtk typst compile report.typ report.pdf`.
- Re-check the abstract, conclusion, and every figure/table you cited after drafting.
- During the review loop, recompile after every Q&A addition and report any compile failure before continuing.
