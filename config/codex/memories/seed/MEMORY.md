# Task Group: Codex memory bootstrap
scope: Minimal starter content for fresh Codex installs before runtime memories are generated.

## Task 1: Initialize local memory files
- Runtime memory lives outside the dotfiles repo at `~/.local/state/codex/memories` and is linked from `~/.codex/memories`.
- Keep this file lightweight; Codex will replace it with validated task-family memories as it runs.
