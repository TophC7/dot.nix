# Backprop — failure to §B to §V

Backprop is the protocol `work-spec` follows when a verification command fails during spec execution. The failure feeds back into the spec so the next reader (you in a future session, another agent) doesn't repeat the same mistake.

The cavekit project introduced this idea; this skill carries the same intent: a failure isn't just a bug to fix, it's a signal that the spec was wrong about something. Capture both the bug AND the corrected understanding.

## When to invoke

- A verification command (acceptance grep, type-check, smoke step) fails during work-spec execution.
- A user-reported bug surfaces while a phase / ticket is in progress and is in-scope (i.e., the same code area).
- A test run that was previously green turns red after an edit.

Do NOT invoke for:
- Bugs unrelated to the active spec — those belong in beads (`bd create --type bug`) without a spec link.
- Pre-existing failures that the spec did not promise to fix — flag in `§C` as known-issue, don't treat as backprop.
- Transient flakes (network timeout, CI runner OOM). Re-run once; if persistent, then it's a bug.

## The six steps

### 1. Add a §B row immediately

Append to the active phase's / ticket's / spec's `§B — Bugs` table:

```markdown
| bd-a3f8 | blocking | T.2 verification: tsc --noEmit failed with TS2339 | T.2 |
```

Schema:
- **id** — beads ID if a beads issue was created (see step 2); otherwise a local ID like `B.1`.
- **severity** — `blocking` (work-spec halts), `required` (work-spec continues but tracks), `noted` (informational).
- **discovery** — *where* the failure was found, including the failing command in code-formatted form.
- **fix-target** — which §T task / phase owns the fix. Often the same task that surfaced the failure.

### 2. Create a beads bug (if `.beads/` exists)

In parallel with step 1, durable-track the bug via beads:

```fish
bd create "<one-line title>" \
  --type bug -p <0 or 1> \
  -d "Failing command: <cmd>\nDiagnosis: <root cause>\nSpec: <spec-name>\nTask: <T.id>" \
  --deps "discovered-from:<task-bd-id>" \
  --labels "spec:<spec-name>,backprop"
```

The §B row's `id` column gets the beads ID returned. Now the bug is durable even if the spec gets compacted out of context.

### 3. Diagnose the root cause

Read the failing output, the relevant files, and adjacent code. The diagnosis goes in:
- The §B row (one-line summary in `discovery`).
- The beads bug body (full reasoning, what was assumed, what's actually true).

### 4. Land the fix

Edit code; re-run the failing verification; confirm green. Don't mark §B resolved until the verification command itself succeeds — clicking the box on a "should be fixed now" is the failure mode this protocol exists to prevent.

### 5. Decide: promote, or close local

After the fix lands, ask: **was this lesson general or local?**

- **General** — every future phase / ticket / spec in this repo would benefit from knowing this. Examples:
  - "valibot's `v.transform` runs before `v.parse`, so default values must come from `v.optional`, not `v.transform`"
  - "the project's lint rule rejects `as unknown as T` casts, so generic adapters need explicit schemas"
  - "this codebase pins React 18; using React 19 hooks fails at runtime"

  → Promote to **§V** (cross-cutting invariant). Add a row to the spec's §V section with the rule and verification:
  ```markdown
  - All API boundaries use valibot. Defaults via `v.optional()`, not `v.transform()`. Verify: `grep -rn 'v.transform.*default' src/api/` returns 0 hits.
  ```
  Close the beads bug with `-r "promoted to §V: <rule>"`.

- **Local** — the fix only matters for the specific code site that broke. Examples:
  - "the `Foo` component's prop `bar` had a stale default after rename"
  - "this test fixture was hardcoded to a removed enum variant"

  → Don't promote. Mark the §B row with `status: resolved` (or remove if the table prefers removal). Close the beads bug with `-r "fixed; local"`.

### 6. Update CLAUDE.md if the §V promotion warrants it

Some promoted invariants are big enough to belong in CLAUDE.md (project-wide rules, not just spec-local). When promoting:
- If the rule is project-wide and load-bearing, add a one-line edit to `todo.md`'s "CLAUDE.md updates" section.
- The actual CLAUDE.md edit lands as part of whatever phase/ticket owns it.

## Examples

### Example 1 — General lesson promoted

Phase 2 of `auth-rewrite`. work-spec runs the phase's acceptance:

```fish
grep -rn 'v.transform.*default' src/api/
```

Expected zero hits. Got three. Diagnose: a prior task added `v.transform(x => x ?? 'guest')` to mimic defaults, but the project convention is `v.optional(v.string(), 'guest')`. Fix the three hits. Decide: this is general — every API boundary in the repo has the same potential trap. Promote.

§V (in `todo.md`) gains:
```markdown
- valibot defaults via `v.optional()`, never `v.transform()`. Verify: `grep -rn 'v.transform.*default' src/api/` returns 0.
```

§B row marked resolved. beads bug closed with reason `promoted to §V: valibot defaults`.

### Example 2 — Local fix, no promotion

Ticket 4 of `cleanup-followups`. Fixes a stale prop name in `<Header>` after a rename. work-spec's acceptance grep fails because one usage in a story file was missed. Fix the one usage. Decide: local — Header is a one-off, no project-wide rule emerges. Don't promote. §B row resolved; beads bug closed `-r "fixed; local"`.

### Example 3 — Bug discovered, but out of scope

work-spec is mid-Phase 1 of `ds-migration` and discovers a logging bug in an unrelated area. Don't backprop into this spec — it's not the §C-defined scope. Instead, file a regular beads bug:

```fish
bd create "Logger drops messages above 4KiB" \
  --type bug -p 2 \
  -d "<details>" \
  --labels "logging"
```

Tell the user the bug was filed; continue Phase 1.

## Why this protocol matters

Without backprop:
- Failures get fixed, but the lesson dies with the conversation.
- Future agents in fresh contexts hit the same trap.
- §V invariants stay aspirational instead of grounded in real failures.
- The spec drifts from a faithful description of the work to a stale wishlist.

With backprop:
- Every failure either teaches the spec something new (§V grows) or is local enough to not matter (closed cleanly).
- Beads carries the bug history independent of the spec, so even radical spec rewrites don't lose the data.
- Future readers see §V as battle-tested rather than speculative.

## What never crosses the boundary

- Backprop edits the spec (§B → §V) and creates beads issues. It does **not** retroactively edit phases that have already closed.
- If a closed phase had a missed §V that this backprop would have caught, note in the new §V row when it was promoted ("promoted in Phase 4 backprop; Phase 2 should be re-verified") rather than reopening the closed phase.
