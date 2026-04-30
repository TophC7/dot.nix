---
name: commit-staged
description: Create a conventional commit from currently staged git changes. Use when the user wants to commit staged work without modifying files. Inspect the staged diff, write an appropriate conventional commit message, attempt the commit once, and stop immediately if it fails.
---

# Commit Staged Changes

Create a conventional commit from the current staged changes.

**Execute this skill directly.** Do not edit files, stage files, unstage files, or fix hook failures as part of this skill.

## Workflow

### 1. Inspect staged changes

Run:

- `git diff --cached --stat`
- `git diff --cached`

If nothing is staged, tell the user and stop.

### 2. Draft the commit message

Build a conventional commit message from the staged diff:

- First line: `type(scope): summary`
- Keep the summary under 72 characters
- Use the most relevant type: `feat`, `fix`, `refactor`, `chore`, `docs`, `style`, `test`, `perf`, `ci`, `build`
- Scope is optional; include it only when it adds clarity
- If there are multiple notable changes, add a blank line and short bullet points
- Do not include trailers such as `Co-Authored-By`

### 3. Create the commit once

Use a heredoc so the message is explicit and non-interactive:

```bash
git commit -m "$(cat <<'EOF'
type(scope): summary line

- important detail 1
- important detail 2
EOF
)"
```

### 4. Stop immediately on failure

If the commit fails for any reason:

- Do not retry
- Do not amend
- Do not edit files
- Do not stage or unstage anything
- Do not bypass hooks
- Show the error output
- Show the exact commit message that was attempted
- Stop and let the user decide what to do

### 5. Report success briefly

If the commit succeeds, show the commit hash and summary.

## Rules

- Commit only what is already staged
- Keep the message grounded in the actual diff
- Prefer one clear scope over over-specifying the subject line
- Keep user-facing output brief
