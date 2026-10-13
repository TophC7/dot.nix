---
description: Create a GitHub pull request from exact committed changes in any local repository.
---

Create a pull request from exact committed changes.

Target or additional user instructions: $ARGUMENTS
Treat an empty value as no explicit target.

1. Resolve the intended local repository from the explicit target, conversation, or current directory. Do not restrict lookup to the current working directory. If no unique repository can be inferred, use `ask` once for its path or target.
2. Launch the `pr` agent:
   Call `task(agent="pr", task="Repository: <resolved absolute path>. User instructions: $ARGUMENTS")`.
3. Report the resulting PR URL, or the agent's blocker verbatim.
4. No further actions or follow-up checks.
