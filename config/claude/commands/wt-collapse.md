# Worktree Collapse

Merge work from the current worktree into a target branch, then remove
the worktree and its companion branch.

## Usage

`/wt-collapse <target-branch>`

## Workflow

1. **Ensure all changes are committed** in the current worktree:
   ```bash
   git status --porcelain
   ```
   If there are uncommitted changes, commit them or ask the user what to
   do before proceeding.

2. **Identify the worktree context**:
   - Current worktree branch name (e.g. `codex/my-task`)
   - Task name extracted from the branch (strip the `codex/` prefix)
   - Worktree path (`git rev-parse --show-toplevel`)
   - Main checkout path (derive from the sibling `-worktrees/` convention:
     if worktree is at `../<repo>-worktrees/<task>`, the main checkout is
     at `../<repo>`)

3. **Switch to the main checkout**:
   ```bash
   cd <main-checkout-path>
   ```

4. **Checkout the target branch**:
   ```bash
   git checkout <target-branch>
   ```
   If the target branch doesn't exist locally, try
   `git checkout -b <target-branch> origin/<target-branch>`.

5. **Merge the worktree branch**:
   ```bash
   git merge <worktree-branch>
   ```
   If there are conflicts, help the user resolve them before continuing.

6. **Remove the worktree and companion branch** using the shared git
   helper:
   ```bash
   git wt-done <task-name>
   ```
   If `git wt-done` fails (e.g. submodule issues), fall back to:
   ```bash
   git worktree remove -f <worktree-path>
   git branch -d <worktree-branch>
   git worktree prune
   ```

7. **Confirm** cleanup is complete and report the final state.

## Worktree Principles

- When the repo contains git submodules, `git worktree move` is
  unreliable and `git worktree remove` may need `-f` even for clean
  worktrees.
- Prefer `git wt-done` / `git worktree remove -f` over moving worktrees
  around.
- Keep the main checkout on `master` whenever practical.

## Error Handling

| Error | Action |
|-------|--------|
| Uncommitted changes | Ask user to commit or stash first |
| Merge conflicts | Help user resolve them, then continue |
| Not in a worktree | Inform user; this command must be run from a worktree |
| `git wt-done` fails | Fall back to `git worktree remove -f` + `git branch -d` |
| Branch not fully merged | Use `git branch -D` only with explicit user confirmation |

## Arguments

$ARGUMENTS:
- `<target-branch>` - Branch to merge worktree changes into (required)
