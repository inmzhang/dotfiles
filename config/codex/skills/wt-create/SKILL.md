---
name: wt-create
description: "Create a new git worktree for a task branch, then switch into it. Use when starting work on a new task that should be isolated from the main checkout."
---

# Worktree Create

Create a new git worktree for a task branch, then switch the working
directory into it.

## Usage

```
/wt-create <task-name>
```

## Workflow

1. **Fetch latest from remote**:
   ```bash
   git fetch origin
   ```

2. **Create the worktree** using the shared git helper:
   ```bash
   git wt-new <task-name> origin/master
   ```
   This creates branch `codex/<task-name>` in a sibling worktree directory
   at `../<repo>-worktrees/<task-name>/`. Parse the output to capture the
   worktree path.

3. **Change into the worktree**:
   ```bash
   cd <worktree-path>
   ```

4. **Confirm** the new working directory and branch, then continue
   working on the task.

## Worktree Principles

- A branch can only be checked out in one worktree at a time. Do not
  park `master` inside long-lived worktrees.
- Keep the main checkout on `master` whenever practical, and create task
  worktrees on dedicated branches.
- Prefer sibling worktree directories under `../<project>-worktrees/`
  (the default `git wt-new` behavior) to keep `git status` in the main
  checkout clean.
- When the repo contains git submodules, `git worktree move` is
  unreliable and `git worktree remove` may need `-f`.

## Error Handling

| Error | Action |
|-------|--------|
| Worktree path already exists | Inform user; offer to cd into it or remove it |
| Branch already checked out elsewhere | Inform user which worktree has it |
| `git wt-new` not available | Fall back to raw `git worktree add -b codex/<task> <path> origin/master` |
