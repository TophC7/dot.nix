# Integration with sibling skills

How `spec`, `work-spec`, `spec-sync`, `spec-check`, `adversarial-review`, and the `.sworm/spec/` system call into beads. The contract is one-way: those skills shell out via `bd`; this skill never reaches back.

## `spec` — exporting §T tasks by default

When `spec` finishes authoring a phased or ticketed `§T — Tasks` table, export the rows as local beads issues by default. Light specs stay Markdown-only unless the user asks for beads tracking.

If `.beads/` is missing, initialize local-only state without asking:

```fish
bd init --stealth
```

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

Echo the new IDs back into the spec's `§T` table in a `bd-id` column so the spec and the graph stay linked. Do not keep Markdown task status as the source of truth for beads-backed specs. Example resulting row:

| bd-id | spec-task | deps | summary | acceptance |
|-------|-----------|------|---------|------------|
| `bd-a3f8` | T.1 | — | Rename `legacy` → `dev` in tokenManager | `grep` returns 0 hits |

After export, run `spec-sync` so the spec has a compact `Current State` block.

## `work-spec` — consuming the ready queue

When `work-spec` runs against a phased or ticketed spec, local beads is the task source of truth:

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

If a phased or ticketed spec has not been exported, or its `bd-id` rows do not resolve in local beads, export it first and rewrite the local IDs. Do not silently fall back to Markdown status for durable specs. Light specs can still use the Markdown table directly unless the user opted into beads tracking.

At the end of the invocation, run `spec-sync` so the checked-in spec shows the current local queue state.

## `spec-sync` — rendering current state

`spec-sync` renders local beads state back into the spec's generated `Current State` block. It does not inspect code, git diffs, or verification results.

Use:

```fish
bd list --all --label spec:<spec-name> --json
bd ready --json --label spec:<spec-name> --limit 1
```

Render:

- closed / in-progress / open counts
- one ready-next issue
- open blockers (`spec:<spec-name>,blocker`)
- open follow-ups (`spec:<spec-name>,followup`)
- open backprop bugs (`spec:<spec-name>,backprop`)

Cap each issue list at five items. If more exist, show the hidden count and the `bd list --label spec:<spec-name>` command.

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
bd list --all --label spec:<spec-name> --json
```

This lets `spec-sync` render the current local queue and lets `spec-check` produce a unified read-only view: spec acceptance + open issues with this spec's label.

## What never crosses the boundary

- `spec`, `work-spec`, `adversarial-review` never read `.beads/*.db` directly. They go through `bd`.
- This skill never edits a spec file, never updates Markdown task status, never appends `§B` rows. It produces issues; the calling skill writes back to the spec.
- Hooks (`bd hooks install`, `bd setup claude`) are user-installed, not skill-installed. The skill *recommends* them; the user enables them.
