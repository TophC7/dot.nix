# Light shape — single-file `SPEC.md`

Use when the work is small enough to read top-to-bottom in 60 seconds. One file, every section in it. Section vocabulary matches phased and ticketed shapes — same §-headings, just collapsed into one document.

When the spec grows past ~200 lines or starts wanting per-phase / per-ticket sub-files, migrate to phased or ticketed. Don't keep stuffing a light spec.

## Directory layout

```
.sworm/spec/<name>/
└── SPEC.md
```

That's it. No `todo.md`, no per-phase files. The whole spec lives in `SPEC.md`.

## Naming

- Spec directory: kebab-case noun phrase (same rule as phased / ticketed).
- The file is always `SPEC.md` — uppercase, fixed name. `work-spec` detects the light shape by the presence of `SPEC.md` and absence of `todo.md`.

## `SPEC.md` — annotated template

```markdown
# <Spec title>

**Started**: 2026-04-30
**Predecessor**: `<spec-name>` (if applicable)
**Shape**: light

<Light specs are Markdown-only by default. If the user opts into beads tracking, add a `Current State` block here and replace `status` with `bd-id` in §T.>

## §G — Goal

<One paragraph: what this work is, why it exists, what's true after it ships. A reader with no context should leave knowing the goal.>

## §C — Constraints (locked decisions + out-of-scope)

- **<Decision area>**: <decision>. <brief why>.
- **<Out of scope>**: <thing>. <why deferred>.

## §I — Interfaces (touched files / public surfaces)

- `<path>` — <what changes>.
- `<path>` — <what changes>.

## §V — Invariants (cross-cutting rules)

- <Rule>. Verify: `<command>` returns `<expected>`.
- <Rule>. Verify: <manual check>.

## §T — Tasks

| id | status | deps | summary | acceptance |
|----|--------|------|---------|------------|
| T.1 | open | — | <task summary> | <verification command or manual step> |
| T.2 | open | T.1 | <task summary> | <verification> |
| T.3 | open | — | <task summary> | <verification> |

<Tasks are the unit of work. work-spec consumes this table directly for Markdown-only light specs. If the user opts into beads tracking, local beads owns status and this table stores `bd-id` links instead. Each task should be small enough to land in one PR (or one focused commit if the whole spec is one PR).>

## §B — Bugs (discovered during execution)

| id | severity | discovery | fix-target |
|----|----------|-----------|------------|

<Empty when the spec starts. work-spec appends rows here automatically when a verification command fails. After a fix lands, the row either promotes to §V (if the lesson is general) or is removed (if local). See `references/backprop.md` for the protocol.>

## Acceptance

- [ ] All §T rows have `status: closed`.
- [ ] `<spec-wide verification command>` succeeds.
- [ ] CLAUDE.md updated if §C called for it.
- [ ] §B is empty (or every row is resolved).

## Risks

- **<Risk name>**: <description>. <how to detect>. <what to do>.

## Notes

<Free-form section for context that doesn't fit elsewhere. Use sparingly — every note that isn't load-bearing is a future maintenance trap.>
```

## When the light shape is the right call

- 1–3 PRs of total work.
- No interlocking phases (all tasks can be reasoned about together).
- The §V invariants are short enough to live alongside §C without their own file.
- The user wants the lowest-overhead durable plan, not the fullest possible plan.

## When to migrate to phased / ticketed

If during execution you find yourself wanting:
- A per-phase risks section that doesn't fit in a single Risks list.
- A per-phase out-of-scope list because tasks are deferring different things.
- More than ~10 §T rows where some block others significantly — the table gets hard to scan.
- A `conventions.md`-style hoist of cross-task rules.

…then the spec has outgrown light. Convert by splitting `SPEC.md` into `todo.md` + per-phase / per-ticket files; preserve the §-section names; commit the conversion as its own PR with `chore(spec/<name>): convert to phased shape` or similar. `work-spec` will pick up the new shape on next run.
