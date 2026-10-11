+++
description = "Create a GitHub pull request from exact committed changes in any local repository."
omp = "pr"
claude = "pr"

[dispatch.single]
agent = "pr"
task = "Repository: <resolved absolute path>. User instructions: {{args}}"
+++

Create a pull request from exact committed changes.

Target or additional user instructions: {{args}}
Treat an empty value as no explicit target.

1. Resolve the intended local repository from the explicit target, conversation, or current directory. Do not restrict lookup to the current working directory. If no unique repository can be inferred, {{askRepo}} for its path or target.
2. {{dispatch}}
3. Report the resulting PR URL, or the agent's blocker verbatim.
4. No further actions or follow-up checks.
