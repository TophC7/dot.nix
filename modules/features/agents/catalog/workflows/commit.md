+++
description = "Create a conventional commit from staged changes."
omp = "commit"
claude = "commit"

[dispatch.single]
agent = "committer"
task = "Inspect staged diff and commit. User focus: {{args}}"
+++

Commit currently staged changes.

Optional user focus: {{args}}

1. {{dispatch}}
2. Report the resulting commit hash and summary line.
3. No further actions or follow-up checks.
