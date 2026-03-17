---
name: ppr
description: >
  Orchestrate multi-agent ping-pong code review through a local file-based
  protocol. Use when the user wants review from multiple coding agents, asks
  for a second opinion from Claude Code, Codex, Gemini, or another terminal
  agent, wants iterative cross-agent review rounds, or explicitly mentions ppr
  or ping-pong review.
---

# PPR

Use the real script path inside the installed skill directory. Common installs
are `~/.agents/skills/ppr/ppr` for Codex and `~/.claude/skills/ppr/ppr` for
Claude Code.

## Runtime Layout

- Script: `<skill-dir>/ppr`
- Default agent config: `<skill-dir>/agents.json`
- Per-project override: `.ppr/agents.json`
- Review state: `.ppr/`

## Command Help

The common workflow is documented below, so you should not need a help probe
just to discover the normal syntax. When you do need the CLI reference, use:

```bash
<skill-dir>/ppr --help
<skill-dir>/ppr help init
<skill-dir>/ppr init --help
```

## Author Workflow

When running PPR as the author:

1. Determine reviewers if the user did not specify them.
2. Start the session:

```bash
<skill-dir>/ppr init \
  --reviewers "claude-code:alice,codex:bob" \
  --max-rounds 3 \
  --context "Short description of the changes"
<skill-dir>/ppr launch
```

3. Wait and collect:

```bash
<skill-dir>/ppr wait --timeout 600
<skill-dir>/ppr collect
```

4. Summarize the review for the user:
- points multiple reviewers agree on
- disagreements worth discussion
- each reviewer verdict

5. After code changes or a written rebuttal:

```bash
<skill-dir>/ppr respond --message "Addressed X, disagree on Y because Z"
<skill-dir>/ppr launch
```

6. Finish when reviewers converge or the user wants to stop:

```bash
<skill-dir>/ppr finish --commit --message "feat: description"
```

## Reviewer Workflow

When launched as a reviewer:

- Read the diff, author context, previous review, and author response from the prompt.
- Review for correctness, regressions, security, performance, readability, and conventions.
- Output only the final markdown review.
- Do not edit files or apply patches.
- Reference concrete file and line locations when possible.
- Tag issues with `[bug]`, `[security]`, `[performance]`, `[style]`, `[suggestion]`, or `[question]`.
- End with exactly one verdict: `LGTM` or `CHANGES REQUESTED`.

## Agent Config

`agents.json` maps agent type to a non-interactive launch command.

Current default examples:

```json
{
  "claude-code": {
    "cmd": "claude -p --session-id \"$SESSION_ID\" --permission-mode plan --output-format text \"$(cat \"$PROMPT\")\"",
    "session_cmd": "claude -p --resume \"$SESSION_ID\" --permission-mode plan --output-format text \"$(cat \"$PROMPT\")\""
  },
  "codex": {
    "cmd": "codex --ask-for-approval never exec --sandbox read-only -o \"$REVIEW_FILE\" - < \"$PROMPT\""
  },
  "gemini": {
    "cmd": "gemini -p \"$(cat \"$PROMPT\")\" --approval-mode plan --output-format text"
  }
}
```

Rules:

- `$PROMPT` is the generated prompt file.
- `$REVIEW_FILE` is optional and should be used only for CLIs that can write just the final answer there.
- `$SESSION_ID` is a stable per-reviewer session identifier.
- `session_cmd` is optional and should be used for round 2+ when an agent can resume a prior session.
- Otherwise the agent should print the final review to stdout.
- Prefer read-only / no-write execution for reviewers.

## Troubleshooting

- `agent type not found`: add or fix the entry in `agents.json`.
- Empty or missing review: inspect `.ppr/round-N/reviews/.stderr-NAME.log`.
- Need repo-specific behavior: add `.ppr/agents.json` in the project.
