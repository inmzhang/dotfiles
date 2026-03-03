# Automation and Guardrails Memory (Codex)

Source migration: `config/claude/rules/hooks.md`.

## Lifecycle checkpoints

Think in three checkpoints for automation:

- Pre-action checks: validate intent and parameters before running tools.
- Post-action checks: run formatting, lint, or validation after edits.
- End-of-task checks: verify behavior and summarize remaining risk.

## Permission safety

- Auto-approval should only be used for narrow, trusted command families.
- Keep exploratory or destructive operations behind explicit approval.
- Prefer targeted approval rules over broad bypasses.

## Progress tracking

Codex equivalent of Todo tracking:

- Use `update_plan` for multi-step work.
- Keep steps concrete and ordered.
- Update status as work advances so progress and assumptions stay visible.

## Validation posture

A small plan should make it easy to spot:

- Missing steps
- Out-of-order execution
- Unnecessary work
- Incorrect granularity
- Requirement misunderstandings
