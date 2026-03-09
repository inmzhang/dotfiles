# Codex memories

This directory is no longer the live Codex memory store.

- Tracked seed files live in `config/codex/memories/seed/`.
- Runtime memories live in `~/.local/state/codex/memories`.
- `make link` recreates `~/.codex/memories` as a symlink to that runtime state path
  and only seeds missing files, so generated memory artifacts stay out of the dotfiles repo.
