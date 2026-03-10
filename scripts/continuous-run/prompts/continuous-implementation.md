Continue working in this repository without waiting for interactive guidance.

Primary objective:
- Keep advancing the highest-value next slice you can justify from the current local repo state.

Run policy for each iteration:
1. Inspect the repo state, recent commits, local instructions, roadmap docs, TODO notes, and failing tests before choosing work.
2. Recover intent from current evidence instead of stale plans. Prefer the smallest high-value slice that makes the project meaningfully better.
3. Implement the chosen slice end-to-end instead of stopping at analysis.
4. Add or update tests or other verification that match the kind of change you made.
5. Update docs, changelogs, or public progress surfaces when the implementation materially changes project status.
6. Respect repo-local safety rules. Do not revert user changes you did not make.
7. Before committing, run the validation commands required by the repo's own instructions. If the repo does not specify them, run the smallest credible validation bundle for the files you changed and record anything you could not verify.
8. If autonomous commits are allowed by local instructions, make small validated commits and push when the repo policy asks for it. Otherwise leave the tree in a clean, well-described state for the next round.
9. If you hit a real blocker or ambiguity, write a concise note describing the blocker and the best next action to the provided next-action file, then stop the run cleanly.

Behavioral goal:
- Do not idle. If implementation stalls, switch to the next defensible thin slice that follows from the repo state, or leave a precise next-action note for the next iteration.
