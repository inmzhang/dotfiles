---
name: skill-workbench
description: >-
  Build, revise, benchmark, and human-review Codex skills with a repeatable eval
  workspace, baseline comparisons, benchmark aggregation, and review artifacts.
  Use when a user wants more than a quick scaffold: creating a serious new
  skill, improving an existing skill after it underperformed, comparing
  revisions, or setting up evals and review loops for skill quality.
---

# Skill Workbench

Use this skill for the heavy-duty part of skill work: solid prompts, reusable resources, evals, baselines, human review, and iteration. For a fast one-pass scaffold with minimal ceremony, the built-in `skill-creator` is usually enough. Use `skill-workbench` when the user wants stronger evidence that a skill actually works.

## Default workflow

1. Understand the skill with concrete examples.
2. Plan the reusable skill contents.
3. Initialize a new skill or import the existing one.
4. Write or revise the skill and bundled resources.
5. Validate the skill folder.
6. Run evals with a baseline.
7. Launch a human review pass.
8. Improve the skill and repeat until the user is satisfied.

Do not stop after scaffolding if the user asked for a serious migration or quality pass. The point of this skill is to close the loop with evidence.

## Communicating with the user

- Match the user's level of technical fluency. Terms like `eval`, `benchmark`, and `assertion` are fine for technical users; explain them briefly when the user does not seem steeped in tooling jargon.
- Keep the user focused on decisions that matter: what the skill should do, what counts as success, and whether the eval outputs are convincing.
- Suggest the default path that fits the skill type, but keep it flexible. Some skills need rigorous baselines; some only need a few realistic review cases.

## Step 1: Understand the skill with concrete examples

Start with the real usage patterns, not abstract capability labels.

Capture:

1. What the skill should enable Codex to do.
2. What user requests should trigger it.
3. What the output should look like.
4. What edge cases or failure modes matter.
5. Whether the task is objective enough to benefit from formal evals.

If the current conversation already contains a workflow worth turning into a skill, mine that conversation before asking fresh questions. Extract the sequence of actions, key corrections, outputs, and repeated decisions first.

## Step 2: Plan the reusable contents

For each concrete example, ask what should become a reusable asset instead of being reinvented each time.

- Add `scripts/` when the same code would otherwise be rewritten repeatedly or when deterministic behavior matters.
- Add `references/` when the skill needs non-trivial background material, schemas, or policies that should be loaded only on demand.
- Add `assets/` when the skill needs templates, icons, boilerplate projects, fonts, or other output files.

Keep `SKILL.md` lean. Put detailed material in references rather than bloating the always-loaded instructions.

## Step 3: Initialize or import the skill

### New skill

When creating a new skill from scratch, initialize the folder with:

```bash
scripts/init_skill.py <skill-name> --path <output-directory> [--resources scripts,references,assets] [--examples]
```

Generate or refresh `agents/openai.yaml` with:

```bash
scripts/generate_openai_yaml.py <path/to/skill-folder> --interface key=value
```

Read `references/openai_yaml.md` before choosing `display_name`, `short_description`, or `default_prompt`.

### Existing skill

When improving an existing skill:

- Preserve the original folder name and frontmatter `name` unless the user explicitly wants a rename.
- Snapshot the old version before major edits if you plan to compare before/after behavior.
- If the installed skill path is read-only, copy it into a writable workspace first.

## Step 4: Write or revise the skill

Write the skill for another Codex instance, not for a human maintainer. Include procedural knowledge, good defaults, and the minimum context another agent would need to execute reliably.

### Frontmatter

`SKILL.md` frontmatter should contain:

- `name`
- `description`

The `description` is the main trigger surface. Put all trigger guidance there, not in a "when to use" body section that the model may never read.

### Body guidance

- Prefer imperative instructions.
- Explain why key steps matter instead of leaning on brittle all-caps rules.
- Show concrete examples when that reduces ambiguity.
- Keep the core document compact and push large details into `references/`.

### OpenAI UI metadata

If the skill should appear cleanly in UI surfaces, keep `agents/openai.yaml` aligned with `SKILL.md`. Regenerate it when the name, description, or default prompt changed materially.

## Step 5: Validate the skill folder

Run the validator after meaningful edits:

```bash
scripts/quick_validate.py <path/to/skill-folder>
```

Fix validation failures before moving on to evals. A broken skill folder invalidates the rest of the loop.

## Step 6: Create evals

If the skill has objectively testable behavior, create 2-5 realistic eval prompts. Save them to `evals/evals.json`:

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User task prompt",
      "expected_output": "Description of what success looks like",
      "files": []
    }
  ]
}
```

See `references/schemas.md` for the richer schema and downstream result files.

Keep prompts realistic. Use the kind of messy, specific request a real user would send, not a clean toy phrasing.

## Step 7: Run evals with a baseline

Use a sibling workspace named `<skill-name>-workspace/`. Organize results by iteration:

```text
<skill-name>-workspace/
  iteration-1/
    <eval-name>/
      eval_metadata.json
      with_skill/
      without_skill/
```

For improvements to an existing skill, replace `without_skill/` with `old_skill/` when the baseline should be the pre-edit version.

### With-skill execution

If the skill is already installed and visible to the current Codex runtime, you may invoke it explicitly by name. If that is not available, emulate skill usage by instructing the subagent to:

1. Read `<skill-path>/SKILL.md`.
2. Read only the specific referenced files needed for the task.
3. Follow the skill's workflow while completing the eval prompt.

This emulation is acceptable for execution-quality testing and is better than pretending a trigger harness exists when it does not.

### Baseline execution

- New skill: same prompt, but do not load the skill.
- Existing skill improvement: compare against a snapshot of the old version when that produces the clearest signal.

### Parallelism

Spawn all with-skill and baseline runs in the same turn when possible so the comparison is contemporaneous. While those runs are in flight, draft assertions and review criteria instead of idling.

### Eval metadata

For each eval directory, write:

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": []
}
```

Use descriptive names, not just `eval-0`.

## Step 8: Draft assertions and capture evidence

Assertions should be objectively checkable and easy to understand in the benchmark viewer. Favor assertions that discriminate between a genuinely good result and a shallow or lucky one.

Good assertion style:

- "The generated CSV includes the `normalized_score` column."
- "The output PDF has three pages."
- "The script used the bundled template rather than recreating the structure ad hoc."

Avoid weak assertions that would pass for many bad outputs.

Save grading results as `grading.json` using the schema in `references/schemas.md`. The viewer expects expectation entries with:

- `text`
- `passed`
- `evidence`

If the environment surfaces run timing or token metadata, save it to `timing.json`. If it does not, record at least wall-clock duration and note that token data was unavailable.

## Step 9: Aggregate and review

After grading:

1. Aggregate the benchmark:

```bash
python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
```

2. Do an analyst pass using `agents/analyzer.md` to surface patterns the summary stats hide.
3. Launch the review viewer:

```bash
python eval-viewer/generate_review.py <workspace>/iteration-N --skill-name "<name>" --benchmark <workspace>/iteration-N/benchmark.json
```

If a browser is unavailable, approval-constrained, or simply inconvenient, prefer:

```bash
python eval-viewer/generate_review.py <workspace>/iteration-N --static <output-path>
```

For iteration 2 and later, pass `--previous-workspace` so the user can compare revisions.

The viewer is for the human first. Get examples in front of the user before over-interpreting the benchmark yourself.

## Step 10: Improve the skill

When feedback comes back:

1. Generalize from the complaint instead of overfitting to one example.
2. Remove prompt weight that is not helping.
3. Explain the reasoning behind important instructions.
4. Look for repeated work across test runs and promote it into `scripts/`, `references/`, or `assets/`.

Then rerun the same eval set into `iteration-(N+1)` and repeat until:

- the user says the skill is good,
- feedback is effectively empty, or
- further edits are not producing meaningful gains.

## Blind comparison

For more rigorous A/B review, use:

- `agents/comparator.md`
- `agents/analyzer.md`

This is optional. Use it when the user explicitly wants to know whether one revision is actually better, not just different.

## Description tuning

Treat description tuning as a manual workflow unless you have verified a stable Codex-side automation path in the current environment.

### Recommended manual loop

1. Draft 12-20 realistic trigger and non-trigger queries.
2. Review them with the editable HTML in `assets/eval_review.html`.
3. Refine the frontmatter `description` based on those queries and live usage.
4. If you want to automate trigger testing with `codex exec`, verify first that the local CLI exposes reliable skill-usage telemetry. On current Codex builds, a `command_execution` that reads the target `SKILL.md` can be treated as heuristic evidence that the skill was consulted, but this is weaker than a dedicated trigger event. Do not promise a trigger-rate benchmark unless you have confirmed that signal in the current environment.

The lack of a verified automation path is a tooling limitation, not a reason to skip description quality entirely.

## Dotfiles-specific install note

When the user wants a tracked skill in this dotfiles repo:

- put the skill under `config/codex/skills/<skill-name>/`
- refresh runtime links with `make relink`
- verify the live path with `readlink -f ~/.codex/skills/<skill-name>`

## Reference files

Read these only when needed:

- `agents/grader.md` for grading assertions against outputs.
- `agents/comparator.md` for blind A/B output comparison.
- `agents/analyzer.md` for post-hoc benchmark analysis and skill-improvement suggestions.
- `references/schemas.md` for the result file formats.
- `references/openai_yaml.md` for `agents/openai.yaml` field rules.

## Summary

The short loop is:

1. Understand the skill.
2. Build the reusable pieces.
3. Write or revise the skill.
4. Validate it.
5. Run realistic evals against a baseline.
6. Put outputs in front of the user.
7. Improve the skill based on evidence.
