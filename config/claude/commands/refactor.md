# /refactor - Clean Up Uncommitted Changes

Review and refactor all uncommitted changes in the working tree. Focus on making comments concise and removing verbosity.

## Process

1. Run `git diff` to see all unstaged changes and `git diff --cached` for staged changes
2. For each modified file, review the changes and refactor:
   - **Trim verbose comments** - rewrite to be concise and direct
   - **Remove obvious comments** - delete comments that restate what the code already says
   - **Tighten prose** - shorter sentences, fewer filler words
   - **Preserve intent** - keep comments that explain *why*, cut those that explain *what*
3. Do NOT change logic, add features, or restructure code beyond comment cleanup
4. Show a summary of what was changed

## Scope

Only touch files with uncommitted changes (`git status`). Do not modify committed, clean files.

## Guidelines

- A good comment answers "why?", not "what?"
- If the code is self-explanatory, the comment can go
- One-liner comments > multi-line block comments for simple notes
- Keep `TODO` and `FIXME` comments — just tighten their wording
