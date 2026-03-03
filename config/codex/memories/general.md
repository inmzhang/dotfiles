# General Engineering Memory (Codex)

Source migration: `config/claude/rules/general.md`.

## Working style

- Resolve ambiguity early. Ask short clarifying questions when requirements are genuinely unclear.
- Run `shellcheck` on shell scripts when edited.
- Use project-local `tmp/` for intermediate artifacts instead of `/tmp` when practical.
- For independent subtasks, parallelize safely. Keep parallelism bounded to avoid context and resource thrash.

## Session hygiene

- If you discover bugs, workflow issues, or incidental follow-up work, record concise notes in `SESSION.md`.
- Do not log accomplishments in `SESSION.md`; only deferred issues.

## Rust guidelines

- Add dependencies with `cargo add`.
- In `eyre`/`anyhow` code paths, prefer `.context(...)` before `?` to preserve failure context.
- Prefer `expect(...)` over `unwrap()` with concise, reasoned messages.
- Use temporary examples under `examples/` for ad-hoc debugging, then remove them.
- Use `quickcheck` for property-style validation and `insta` for snapshot regression coverage when suitable.

## compile_fail testing

- Use focused `compile_fail` doctests for one specific failure condition per test.
- Clearly document why the code should fail.
- If no natural host item exists, add a private `#[allow(dead_code)]` item and document purpose.
- Verify expected failure reason with temporary examples before finalizing.

## Git and commit quality

- Use `git mv` when moving tracked files.
- Commit messages should explain non-obvious tradeoffs.
- Follow semantic commit style where possible.
- Wrap prose in commit bodies/titles following common git formatting conventions.

## Documentation and code style

- Prefer realistic names in examples.
- Document intentional omissions the reader might otherwise expect.
- Add TODOs for intentionally deferred behavior.
- Emphasize literate programming for complex logic: explain why, maintain top-down narrative, keep comments near important decisions, and avoid over-abstraction.

## Codex execution discipline

- Run commands in the default sandbox first.
- Escalate only after a concrete permission or environment failure indicates it is necessary.
- Avoid combining risky or approval-sensitive commands in dense command chains.
- Prefer temp files over fragile pipelines for complex tool handoffs during debugging.

## Debugging mindset

- Watch for XY problem patterns: a narrow implementation question may hide a different underlying objective.
- Confirm the underlying goal before over-optimizing a proposed method.
