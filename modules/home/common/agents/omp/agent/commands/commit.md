---
description: Create a conventional commit from staged changes using the @commit agent.
---

Commit currently staged changes.

Optional user focus: $ARGUMENTS

1. Launch the `committer` agent:
   Call `task(agent="committer", task="Inspect staged diff and commit. User focus: $ARGUMENTS")`.
2. Report the resulting commit hash and summary line.
3. No further actions or follow-up checks.
