# Stealth vs shared

Beads can store its data inside the repo and commit it (shared) or keep it local-only (stealth). The choice is one-time per repo and rarely changes.

## Shared (default for repos you own)

```fish
bd init
```

- `.beads/issues.jsonl` and `.beads/*.db` are committed to git.
- Issues survive across machines, sync between team members, and merge cleanly via beads' git merge driver.
- `bd hooks install` wires git pre-commit (flush JSONL), post-merge (re-import), pre-push (staleness check), and post-checkout (import) so working with branches is transparent.
- This is the right default when you own the repo, work on multiple machines, or share it with a team / agent fleet that all use beads.

## Stealth (default for repos you don't own)

```fish
bd init --stealth
```

- `.beads/` is excluded via per-repo `.git/info/exclude` (not `.gitignore`, so collaborators don't see it).
- Claude Code settings get a project-local nudge to run `bd onboard` instructions on session start.
- Nothing about beads ends up in the repo's history; the issue store is fully local.
- Use this when you're contributing to someone else's repo, when the project's policy disallows extra committed files, or when issues are personal scratch you don't want to share.

## Switching modes

There's no clean toggle. The supported path is:

1. `bd export > backup.jsonl` — preserve the data.
2. Delete `.beads/`, undo any `.git/info/exclude` or `.gitignore` lines.
3. Re-init in the desired mode.
4. `bd import < backup.jsonl --from-jsonl`.

In practice, pick the mode at `bd init` time and don't change it.

## Implications for sibling skills

- `spec` exporting `§T` to beads, `work-spec` consuming `bd ready`, and `adversarial-review` emitting findings all work identically in both modes. Stealth doesn't break the skill flow; it only changes whether the data leaves your machine.
- In stealth mode, mention to the user once: "issues are local-only on this repo; another machine won't see them" so the user isn't surprised when they switch hosts.

## How to choose at `bd init` time

Ask once, briefly:

> "Initialize beads here. Commit `.beads/` to git so issues sync across machines/team (recommended for repos you own), or keep them local-only via stealth mode (recommended for repos you don't own)?"

Default to shared if `.git/config` shows the user as the repo owner / a maintainer, otherwise default to stealth. Either way, present the choice; don't decide silently.
