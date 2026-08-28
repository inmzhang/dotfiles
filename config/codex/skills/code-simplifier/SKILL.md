---
name: code-simplifier
description: Simplify recently modified code for clarity, consistency, and maintainability without changing behavior. Use when asked to simplify, clean up, or refactor code for readability, or to review recent changes for unnecessary complexity. Default to changed code unless the user names a broader scope.
---

# Code Simplifier

Improve code structure while preserving its observable behavior.

## Scope

- Follow the user's explicit scope. Otherwise inspect code changed in the current session or visible in the working-tree diff.
- Read applicable `AGENTS.md` files and nearby code before editing so the result follows project conventions.
- Do not modify unrelated code. For review-only requests, report opportunities without editing.

## Simplification

- Remove redundant code, unnecessary abstractions, and avoidable nesting.
- Consolidate related logic and improve unclear names when doing so preserves behavior.
- Prefer readable control flow over dense expressions; avoid nested ternaries.
- Remove comments that merely restate the code, while preserving comments that explain intent or constraints.
- Keep useful abstractions and separation of concerns. Fewer lines are not inherently simpler.
- Preserve public APIs, outputs, side effects, error behavior, and supported edge cases unless the user explicitly requests a behavior change.

## Verification

Review the resulting diff and run the smallest relevant existing tests, checks, or build command. Report any verification that could not be run.
