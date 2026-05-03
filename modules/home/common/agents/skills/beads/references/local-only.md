# Local-only beads policy

Beads is always private machine state in this repo. Specs are the durable checked-in plan; beads is the local execution queue.

## Init

Use the local-only init path without asking:

```fish
bd init --stealth
```

Do not offer a visibility choice. Do not suggest committing `.beads/`. Do not run git sync as part of normal agent work.

## What local-only means

- `.beads/` stays out of git.
- Beads state does not sync between machines.
- Specs can contain `bd-*` IDs and a generated `spec-sync` snapshot, but the issue database remains local.
- Another machine can recreate beads issues from the spec if needed. Existing `bd-*` IDs in tracked specs are local handles and may be rewritten there.

## Agent behavior

- If `.beads/` exists, use it.
- If `.beads/` is missing and durable task state is needed, run `bd init --stealth`.
- For phased / ticketed specs, export tasks to local beads by default.
- For light specs, use Markdown status unless the user asks for beads tracking.
- Never ask whether beads should leave local state.
