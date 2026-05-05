# Phased shape — full skeleton

Use when the work is sequenced and each phase blocks the next. Order matters; one PR per phase. Section vocabulary (§G/§C/§I/§V/§T/§B) matches the light and ticketed shapes — readers don't re-orient when switching.

## Directory layout

```
.sworm/spec/<name>/
├── todo.md
├── conventions.md           — only if 3+ phases share rules
├── phase-0-<slug>.md
├── phase-1-<slug>.md
└── phase-N-<slug>.md
```

Naming rules:
- Spec directory: kebab-case noun phrase (`lib-refactor`, `auth-consolidation`, `dashboard-ds-migration`).
- Phase files: `phase-<N>-<short-slug>.md`. Slug is 2-4 words, kebab-case, action-y (`stop-bleeding`, `api-boundary`, `stores-relocate`).
- Phase 0 is conventionally "stop the bleeding" or "groundwork" — low-risk fixes that unblock everything else. Use it when the codebase has accumulated debt that would obstruct the bigger phases.

## `todo.md` — annotated template

```markdown
# <Spec title>

**Started**: 2026-04-30
**Predecessor**: `<spec-name>` (link if applicable, brief note on what it produced)
**Guiding principle**: <one sentence — e.g., "behavior-preserving where possible, intentional behavior changes flagged per phase">

## Current State

<!-- spec-sync:start -->
Not synced yet.
<!-- spec-sync:end -->

## §G — Goal

<One paragraph that answers: what is this work, why does it exist, what will be true after it ships. A reader who finds this file with no other context should leave knowing the goal.>

## §C — Constraints (locked decisions + out-of-scope)

<Decisions made during the interview. These are commitments — every phase respects them. Each bullet: WHAT was decided + brief WHY.>

- **Validation library**: valibot (~3kB gz, tree-shakes per validator). All API boundaries get schemas.
- **Branded IDs**: introduce in Phase 1. `PatientId`, `EncounterId` as phantom types via `v.brand`.
- **<Decision area>**: <decision>. <rationale>.
- **Each phase = one PR.** `tsc --noEmit` and `pnpm check:fix` must pass per phase.

**Out of scope (entire spec):**
- <Tempting work explicitly deferred at the spec level, with a note on whether a future spec owns it.>

## §I — Interfaces (touched files / public surfaces)

<Files and surfaces this spec changes. A reader should be able to see at a glance which parts of the codebase are in scope.>

- `src/lib/auth/*` — middleware split into request and session layers.
- `src/api/handlers/*` — boundary-validated via valibot schemas.
- `db/migrations/2026-04-*.sql` — branded ID columns.

## §V — Invariants (cross-cutting rules)

<The rules every phase enforces. Each invariant is testable.>

- All API boundaries have valibot schemas. Verify: `grep -rn 'export.*Schema' src/api/ | wc -l` matches handler count.
- No `as <Type>` casts of unknown values. Verify: `grep -rn ' as [A-Z]' src/ | grep -v 'as const'` returns 0 hits.
- `tsc --noEmit` passes per phase boundary.

## CLAUDE.md updates (apply incrementally per phase)

<Concrete edits to project CLAUDE.md, attributed to the phase that makes them. Doing this here forces the team to think about which rules change and prevents CLAUDE.md drift.>

- Drop "<old rule>" — replace per Phase 1.
- Update "<rule>" — add the feature-local clause per Phase 3.
- Add "<new rule>" — per Phase 0.

## Phases

- **Phase 0** — <name> → [phase-0-<slug>.md](phase-0-<slug>.md)
  *<one-line summary, italicized>*
- **Phase 1** — <name> → [phase-1-<slug>.md](phase-1-<slug>.md)
  *<one-line summary>*
- **Phase N** — Polish → [phase-N-polish.md](phase-N-polish.md)
  *Remaining cleanup that didn't fit anywhere else.*

<This list is stable onboarding context. Live progress lives in local beads and the generated Current State block.>

## Final state

<Concrete observable properties of the codebase after the last phase. A QA-style description, not a process description.>

After Phase N:
- `src/lib/` contains only cross-cutting code (list).
- Zero `as <Type>` casts of unknown values at API boundaries.
- All IDs branded; cross-ID-type bugs fail at compile time.
- CLAUDE.md reflects the new conventions.

## Acceptance (overall)

<Repo-wide checks that all phases together must satisfy.>

- [ ] `tsc --noEmit` clean across all phases
- [ ] `pnpm check:fix` clean
- [ ] Smoke test: <full user journey>
- [ ] `grep -rn '<forbidden pattern>' src/` returns 0 hits
- [ ] CLAUDE.md updated per the list above
```

## `conventions.md` — when to include

Include only when 3+ phases share the same rules. Below that, repeat the rule in each phase file — readers shouldn't have to chase across files for a 2-line rule.

When you do include it, structure by topic, not phase:

```markdown
# Cross-Phase Conventions

Read this once before any phase. Defines patterns every phase enforces.

## <Topic — e.g., Validation: valibot at boundaries>

**Rule**: <the rule, in one or two sentences>

**Pattern**:
```ts
<minimal code example showing correct usage>
```

**Where things live**: <paths>

**Naming**: <conventions>

## <Next topic>

...
```

Topics commonly covered: validation, IDs/branded types, query keys, store conventions, React/framework conventions, naming/casing, comment style, test runner, file-write hygiene, what to do when blocked.

## `phase-N-<slug>.md` — annotated template

```markdown
# Phase N — <Title>

<One paragraph: what changes, why grouped this way, what's NOT changing. Set the reader's expectation for blast radius.>

**Pre-reqs**: <prior phases that must land first, or "none">
**Blast radius**: <small / medium / large> — <e.g., "most changes touch <10 files each">
**Behavior change**: <"none — pure refactor" OR explicit list>

## §T — Tasks

| bd-id | spec-task | deps | summary | acceptance |
|-------|-----------|------|---------|------------|
| `bd-a3f8` | N.1 | — | Rename `legacy` → `dev` in `tokenManager.ts` | `grep -rn 'legacy' src/ | wc -l` returns 0 |
| `bd-b7c2` | N.2 | N.1 | Update call sites | `tsc --noEmit` clean |
| `bd-c1d4` | N.3 | N.2 | Add migration note to CLAUDE.md | manual review |

<Each row is a task that can be claimed and worked. For phased specs, local beads is the source of truth for status, deps, claims, and blockers.>

### N.1 <Task title>

<Why this task. What problem it solves.>

<File paths with line numbers when known: `src/lib/foo.ts:42`.>

<Concrete steps. Where useful, include:>

```fish
# verification commands
grep -rn "<pattern>" src/ | wc -l
```

```ts
// before
<old code>

// after
<new code>
```

<Verification: how the developer confirms this task is done.>

### N.2 <Task title>

...

## Acceptance

<Phase-level acceptance — every bullet must be checkable.>

- [ ] `<command>` produces `<expected output>`
- [ ] `grep -rn '<pattern>' src/` returns 0 hits
- [ ] Smoke test: <user-visible action> works as before
- [ ] No new `<forbidden symbol>` introduced

## §V — Invariants (phase-local)

<Rules that hold WITHIN this phase. Spec-wide invariants live in todo.md.>

- <Phase-local rule, with verification>

## §B — Bugs (discovered during execution)

| id | severity | discovery | fix-target |
|----|----------|-----------|------------|

<Empty when the phase starts. work-spec appends rows here when verification commands fail. After a fix lands, the row either promotes to §V (if the lesson is general) or is removed.>

## Risks

<Each risk: name + what could go wrong + detection + mitigation. Be paranoid here. The future agent or developer reading this in a fresh context cannot intuit what you knew at write-time.>

- **<Risk name>**: <description>. <How to detect>. <What to do>.
- **Symbol collision**: pre-check with `grep -rn 'interface Patient\b' src/`. If a hit appears that isn't the renamed type, rename it first.
- **Persist version bump**: users with v1 storage lose in-progress state. Acceptable because the route's URL params re-hydrate the relevant ID.

## Out of scope (later phases)

<Tempting work that's deferred, attributed to the phase that owns it.>

- Splitting `<file>` (Phase 3)
- Replacing `<pattern>` (Phase 1)
```

## Phase ordering heuristics

- Phase 0 is conventionally a low-risk groundwork phase — fix build-breakers, delete dead code, document existing constraints. Land it first to make the other phases possible.
- Foundational phases (introducing a library, defining a base pattern) come early so later phases can assume them.
- Riskiest behavior changes come *late* — after the supporting infrastructure is in place. A risky change with no safety net is worse than the same change against valibot-validated boundaries.
- A "Polish" final phase is fine. It's where logger sweeps, comment passes, and CLAUDE.md final reconciliation live.
