---
name: PR Review
summary: Post a PR review with cleanup changes and inline findings comments
---

Review the PR with a comment detailing cleanup changes and findings from `local://findings.md` (or recent review output).

1. **Push commits**: If any cleanup or local commit was made, push it to the remote branch first.
2. **Review mode**: Submit as a PR review comment (`COMMENT`). Do not approve or request changes unless a finding is clearly an indisputable, breaking bug.
3. **Cleanup summary**: If cleanup changes were committed, summarize what was done concisely by file or component with the commit hash. If none, omit.
4. **Findings on lines**: Comment on the unaddressed findings (Confirmed / Worth a look). Place comments directly on the actual diff lines where the issues occur via inline review comments whenever possible. Fall back to the review body with `file:line` anchors only if a line is outside the PR diff.
5. **Tone & scope**: Keep observations short and strictly factual. Do not judge or advise on whether something "should" or "must" be fixed—just inform, unless it is clearly a broken bug that requires fixing.
6. **Signature**: Append your signature.

PR or additional focus: 
