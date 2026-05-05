---
name: pr
description: Create a pull request from the current branch's committed and pushed changes. Use when the user wants to open a PR without modifying files. Inspect the branch, commits, and diff against main, push the branch if needed, create the PR once with a concise title and summary, and return the PR URL.
---

# Create Pull Request

Create a pull request from the current branch's committed and pushed changes.

**Execute this skill directly.** Do not edit files, create commits, amend commits, or fix branch state issues beyond pushing the current branch when needed for PR creation.

## Workflow

### 1. Inspect the current branch state

Run these to understand the PR contents:

- `git branch --show-current`
- `git log --oneline main..HEAD`
- `git diff main...HEAD --stat`
- `git status --short`
- `git rev-parse --abbrev-ref @{upstream} 2>/dev/null`

If there are no commits between `main` and `HEAD`, tell the user and stop.

If there are uncommitted changes, warn the user briefly, but continue using only the committed diff for the PR.

### 2. Decide which branch should back the PR

Treat `dev/<username>` branches as local-only working branches.

If the current branch matches `dev/*`:

- Do not push `dev/*`
- Do not create the PR from `dev/*`
- Create a new PR branch at the current committed `HEAD`
- Base that PR branch on the exact commits currently in `main..HEAD`
- Assume the user has already rebased their local `dev/*` branch onto `main` as needed

Create a concise branch name derived from the work, for example:

- `feat/room-ds-migration`
- `fix/auth-token-refresh`
- `refactor/dashboard-layout`

Use `git branch <pr-branch-name>` to create the branch pointer without moving the user off their local `dev/*` branch.

If the current branch does not match `dev/*`, use the current branch as the PR branch.

### 3. Ensure the PR branch is pushed

If the PR branch has no upstream, push it:

```fish
git push -u origin <pr-branch-name>
```

If the PR branch already exists remotely, push it with:

```fish
git push -u origin <pr-branch-name>
```

If PR creation fails because the remote PR branch is missing or stale, push that PR branch once and retry PR creation once.

Never push `dev/*` branches.

### 4. Draft the PR title and body

Analyze all commits in `main..HEAD` and the full `main...HEAD` diff summary.

Build:

- A short conventional-style title under 70 characters
- A concise body in this format:

```md
## Summary
- bullet 1
- bullet 2
```

Rules:

- Keep the summary grounded in the actual changes
- Use 1 to 3 bullets
- Do not include "Test plan", "Testing", or "How to test"
- Do not pad with unnecessary detail

### 5. Create the PR once

Use a non-interactive command with an explicit body:

```fish
set pr_body (string join \n -- \
    "## Summary" \
    "- bullet 1" \
    "- bullet 2" \
    | string collect)

gh pr create --head "<pr-branch-name>" --title "the title" --body "$pr_body"
```

If the PR branch is the currently checked out branch, still pass `--head` explicitly.

### 6. Stop on failure

If PR creation still fails after the allowed push-and-retry path:

- Do not keep retrying
- Do not edit files
- Do not create or amend commits
- Show the error output
- Show the exact title and body that were attempted
- Stop and let the user decide what to do

### 7. Report success briefly

If the PR succeeds, return the PR URL.

## Rules

- Base the PR on committed changes only
- Analyze all commits in the branch, not just the latest commit
- If starting from `dev/*`, create and push a separate PR branch from the current committed `HEAD`
- Keep the PR body concise and scannable
- Prefer one clear title over an over-specified one
- Keep user-facing output brief
