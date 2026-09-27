---
description: Review working-tree changes or commits from a hash up for reuse, quality, efficiency, and hidden risk, then apply safe fixes.
---

Run the cleanup workflow against the current working tree or an inclusive commit range through HEAD.

Optional commit and user focus: $ARGUMENTS
If arguments include a commit, review from that commit forward. Remaining text is focus.

1. Confirm the current directory is inside a Git repository. If not, stop with `/cleanup requires a git repository.`
2. Capture the exact, complete diff without truncating or summarizing:
   - If a commit is given: diff from that commit through HEAD (`git diff <commit>^..HEAD`). Stop if invalid or empty.
   - Otherwise: read `git status --porcelain`. If empty, stop with `/cleanup: no working-tree changes to review.` Capture `git diff HEAD`. If empty, stop with `/cleanup: working tree changes produced an empty diff.`
3. Launch exactly one parallel `task` batch containing these four agents:
   - `cleanup-reuse-scout`
   - `cleanup-quality-scout`
   - `cleanup-efficiency-scout`
   - `cleanup-audit-scout`
4. Give every scout the same full diff through one artifact or file path, plus any optional user focus. Each task must tell the scout to read that diff, inspect the repository where needed, and return findings only. Do not launch any other review agent.
5. Wait for all four scouts. If you created a temporary filesystem diff, remove it after every scout has finished.
6. Apply the combined findings directly to the working tree.

Apply rules:
1. Do not re-derive findings unless needed to verify safety.
2. Apply only findings that are clearly correct and worth doing now. Skip false positives without arguing.
3. Stay in lane: change only the lines a finding identifies; do not refactor surrounding code.
4. Preserve behavior, error handling, and existing abstraction boundaries.
5. Do not stage, commit, or push. The user reviews before committing.

After applying, return one tight summary block:
- **Applied:** one short bullet per fix with `file:line`.
- **Skipped:** one short bullet per skipped finding with the reason it was wrong or out of scope. Omit this section if empty.
- **Worth a look:** one short bullet per risky, ambiguous, or larger finding not applied. Audit findings always land here, never in Applied: keep each one's scenario, decision needed, and check so the user can act without re-deriving it. Omit this section if empty.

No narration or preamble.
