---
name: spec-sync
description: >-
  Render compact local beads state into a `.sworm/spec/<name>/` spec's generated Current State block. Use when the user says "sync the spec", "sync spec status", "update current state", after `work-spec` closes or creates spec-labeled issues, or before handing a beads-backed spec to another agent. This skill is intentionally lightweight: it reads beads and the spec index only; it does not inspect code, run acceptance checks, or infer progress.
---

# spec-sync

Render local beads state into a spec's `Current State` block. This keeps `todo.md` / `SPEC.md` readable for humans without making Markdown the task tracker.

`spec-sync` answers: **what does local beads say is the current queue state?**

It does not answer: **does the spec still match the code?** That is `spec-check`.

## When to trigger

- "sync the spec" / "sync spec status" / "update current state"
- Before handing a beads-backed spec to another agent
- At the end of a `work-spec` invocation
- After creating or closing spec-labeled blockers, follow-ups, or backprop bugs

Do not run it for one-shot Markdown-only light specs unless the user opted that spec into beads tracking.

## Hard boundaries

- Read local beads state via `bd`; never read `.beads/*.db` or JSONL directly.
- Read only the spec index file: `todo.md` for phased / ticketed, `SPEC.md` for light.
- Do not read implementation files.
- Do not run acceptance commands, tests, builds, greps, or `git diff`.
- Do not infer whether a task is done from code.
- Rewrite only the generated `Current State` block.

## Locate target

1. Resolve the spec directory under `.sworm/spec/<name>/`.
2. Pick the index file:
   - `todo.md` if present.
   - `SPEC.md` otherwise.
3. If neither exists, stop and say the spec shape is invalid.
4. If `.beads/` is missing, stop and say there is no local beads state to render.

## Read beads state

Use these commands:

```fish
bd list --all --label spec:<spec-name> --json
bd ready --json --label spec:<spec-name> --limit 1
```

For focused lists, use labels:

```fish
bd list --status open --label spec:<spec-name>,blocker --json
bd list --status open --label spec:<spec-name>,followup --json
bd list --status open --label spec:<spec-name>,backprop --json
```

Count issues by status from the `bd list --all` result. Use beads statuses exactly as returned.

## Render format

Use this exact section shape:

```markdown
## Current State

<!-- spec-sync:start -->
**Last synced**: 2026-05-02
**Progress**: 2 closed, 1 in progress, 5 open
**Ready next**: `bd-a3f8` · P1 task · Add local-only beads policy
**Blockers**: none
**Follow-ups**: `bd-b7c2` · Clarify handoff docs
**Backprop bugs**: none
<!-- spec-sync:end -->
```

Rules:

- `Last synced` uses local date in `YYYY-MM-DD`.
- `Progress` includes closed, in-progress, and open counts.
- `Ready next` shows only the first `bd ready` result. If none, write `none`.
- `Blockers`, `Follow-ups`, and `Backprop bugs` show open issues only.
- Cap each issue list at five items.
- If a list has more than five issues, append `(+N more; run bd list --label spec:<spec-name>)`.
- Use the beads CLI line format: `` `bd-id` · P<priority> <type> · <title> ``.
- Keep the block compact; do not include completed task history or close reasons.

## Write behavior

If the index already has markers:

```markdown
<!-- spec-sync:start -->
...
<!-- spec-sync:end -->
```

replace only the marker contents.

If the markers are missing:

1. Insert `## Current State` after the title and metadata block, before the first `## §G — Goal`.
2. Add the marker block.
3. Do not rearrange any other spec content.

If the index has `## Current State` but no markers, replace that section only if it is clearly generated. Otherwise stop and ask the user to add markers.

## Relationship to other skills

- `spec` creates the initial `Current State` block after exporting phased / ticketed tasks to beads.
- `work-spec` runs `spec-sync` after closing, blocking, or filing follow-up work for a beads-backed spec.
- `spec-check` verifies acceptance and invariants against the repo. It never calls `spec-sync` and never edits the spec.

## Anti-patterns

- Reading code to decide whether a bead should be closed. That is `work-spec`.
- Running acceptance checks. That is `spec-check` or `work-spec`.
- Adding a running log of completed work. Beads close reasons already preserve that history.
- Expanding the snapshot until it becomes a second task tracker.
