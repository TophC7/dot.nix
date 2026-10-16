---
name: PR Merge
summary: Push fixes, approve with summary of resolved findings, and merge PR
---

Push the latest commits, approve the PR with a summary of the cleanup changes and resolved findings, and merge it.

1. **Push commits**: Push any local fix or cleanup commits to the remote tracking branch (`git push`).
2. **Approve PR**: Submit an approving review (`gh pr review --approve -b "..."`) on the active PR (fall back to `--comment` if self-approval is restricted).
   - Summarize the cleanup changes and resolved findings (from `local://findings.md` or conversation) concisely by file or component with commit hashes.
   - Keep the summary brief and factual.
   - Append your signature (`> OMP 🤖 <MODEL IN USE>`).
3. **Merge**: Merge the PR using squash merge and delete the branch (`gh pr merge --squash --delete-branch`). If checks are pending or required by branch protection, enable auto-merge (`gh pr merge --auto --squash --delete-branch`).

PR or additional guidance: 
