# Integration with sibling skills

How `spec`, `work-spec`, `adversarial-review`, and the `.sworm/spec/` system call into beads. The contract is one-way: those skills shell out via `bd`; this skill never reaches back.

## `spec` — exporting §T tasks

When `spec` finishes authoring a `§T — Tasks` table (any shape: phased, ticketed, or single-file), offer to export the rows as beads issues. The export is opt-in.

For each row:

```fish
bd create "<task title>" \
  --type task \
  -p <priority> \
  -d "<task summary from spec>" \
  --acceptance "<acceptance bullets joined>" \
  --labels spec:<spec-name>
```

Mirror dependencies row-by-row after creation:

```fish
bd dep add <child-id> <parent-id>
```

Echo the new IDs back into the spec's `§T` table in an `id` column so the spec and the graph stay linked. Example resulting row:

| id | spec-task | deps | summary | acceptance |
|----|-----------|------|---------|------------|
| `bd-a3f8` | T.1 | — | Rename `legacy` → `dev` in tokenManager | `grep` returns 0 hits |

Don't auto-export if `.beads/` doesn't exist yet — ask the user about init first (see `stealth-vs-shared.md`).

## `work-spec` — consuming the ready queue

When `work-spec` runs against a spec whose `§T` was exported to beads:

```fish
bd ready --json --label spec:<spec-name>
```

Pick the first issue in the result, claim it, and execute:

```fish
bd update <id> --claim
# ... do the work, run acceptance commands ...
bd close <id> -r "<one-line summary>" --suggest-next
```

`--suggest-next` prints newly-unblocked work, eliminating a separate `bd ready` round-trip when running through a queue.

If the spec has not been exported, fall back to the spec's own phase / file order. Don't silently create issues mid-execution; that crosses the one-way boundary.

### Backprop on verification failure

When a `work-spec` verification command fails, two writes happen, in this order:

1. Append a `§B` row in the spec with the failing command and diagnosis.
2. Create a beads bug so the failure is durable even if the spec gets truncated:
   ```fish
   bd create "<failure title>" \
     --type bug -p 1 \
     -d "Failing command: <cmd>\nDiagnosis: <root cause>" \
     --deps discovered-from:<current-task-id> \
     --labels spec:<spec-name>,backprop
   ```

After the fix lands:

- If the lesson is general (a new project-wide invariant), promote it to `§V` in the spec; close the beads bug with `-r "promoted to §V"`.
- If the lesson is local, close `§B` in the spec; close the beads bug with `-r "fixed; local"`.

### True blockers

When `work-spec` declares a true blocker (per its existing definition), create a P0 issue and report the ID:

```fish
bd create "BLOCKER: <one-line>" \
  --type bug -p 0 \
  -d "<full blocker context: phase, sub-task, what failed, options considered>" \
  --labels spec:<spec-name>,blocker
```

Surface the new ID to the user along with the blocker context.

## `adversarial-review` — emitting findings

After a review concludes, offer (or auto-execute if the user passes the relevant flag) to create one beads issue per Blocking / Required finding:

```fish
# Blocking
bd create "<finding title>" \
  --type bug -p 0 \
  -d "Location: <path:line>\nFailure mode: <issue cell>\nFix: <fix cell>" \
  --labels review,blocking

# Required
bd create "<finding title>" \
  --type bug -p 1 \
  -d "Location: <path:line>\nFailure mode: <issue cell>\nFix: <fix cell>" \
  --labels review,required
```

Suggestions are not auto-emitted. If two reviews flag the same `path:line`, dedupe by searching first:

```fish
bd list --label review --desc-contains "<path:line>" --json
```

If the search returns a hit, append a comment via `bd comments add <id> "<note>"` instead of creating a duplicate.

## `.sworm/spec/` — round-tripping

Beads' `--labels spec:<spec-name>` is the seam. Any issue tagged with that label belongs to the spec; any spec can resolve its issues with:

```fish
bd list --label spec:<spec-name> --json
```

This lets `spec-check` (the read-only drift report) produce a unified view: spec acceptance + open issues with this spec's label.

## What never crosses the boundary

- `spec`, `work-spec`, `adversarial-review` never read `.beads/*.db` directly. They go through `bd`.
- This skill never edits a spec file, never updates `todo.md` checkboxes, never appends `§B` rows. It produces issues; the calling skill writes back to the spec.
- Hooks (`bd hooks install`, `bd setup claude`) are user-installed, not skill-installed. The skill *recommends* them; the user enables them.
