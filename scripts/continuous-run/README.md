# continuous-run

Generic local automation for running Codex or Claude Code continuously against
any git repository.

## Layout

- `continuous-codex.sh` runs `codex exec` / `codex exec resume`
- `continuous-claude.sh` runs `claude --print`
- `prompts/continuous-implementation.md` is the shared generic base prompt
- `lib/common.sh` holds repo resolution, repo fingerprinting, and prompt helpers

## Usage

Run from inside the target repository:

```sh
~/dotfiles/scripts/continuous-run/continuous-codex.sh
~/dotfiles/scripts/continuous-run/continuous-claude.sh --safe
```

Or target a repo explicitly:

```sh
~/dotfiles/scripts/continuous-run/continuous-codex.sh --repo ~/open-source-project/qrippy
~/dotfiles/scripts/continuous-run/continuous-claude.sh --repo ~/open-source-project/qrippy --parallel
```

## Parallel feature flag

Parallel prompting is intentionally opt-in:

- `--parallel`
- `CONTINUOUS_RUN_ENABLE_PARALLEL=1`

When enabled:

- Claude prompt guidance tells Claude Code to use parallel agent teams for
  independent workstreams.
- Codex prompt guidance tells Codex to use multi agents only for independent,
  parallelizable work with disjoint write scopes.

## State directories

By default the scripts store session state inside the target repository:

- Codex: `<repo>/.codex-loop/`
- Claude: `<repo>/.claude-loop/`

Override them with `CODEX_STATE_DIR` or `CLAUDE_STATE_DIR` if needed.
