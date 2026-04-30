---
name: spec
description: Author a thorough work plan as a `.sworm/spec/<name>/` directory before implementation begins. Use this skill whenever the user wants to "spec out", "plan", "design", "scope", or "break down" any non-trivial feature, refactor, migration, or initiative — anything large enough that a single PR or single conversation won't carry it. Triggers on phrases like "create a spec", "let's plan this", "draft a refactor plan", "scope out this work", "break this down into phases", or when the user references existing `.sworm/spec/` work. Also use proactively when the user describes work that will obviously span multiple PRs or sessions and there is no spec yet — surface the option before diving into code. The skill enforces a clarifying-questions phase up front so the resulting document is load-bearing enough that future work can reference it without re-deriving context.
---

# spec

A spec is a durable plan checked into the repo at `.sworm/spec/<name>/`. It exists so that future-you (or a future agent in a fresh conversation) can resume the work without re-deriving every decision. The whole point is that the document survives context compaction.

If the spec is shallow, every future session re-litigates the same questions. If it's thorough, every future session just executes. **The interview phase is where the value is created.** Don't skip it.

## When this skill applies

Use it when work meets any of these:
- Spans multiple PRs or multiple working sessions.
- Has interlocking phases (a thing has to land before another thing can).
- Needs decisions locked in (lib choice, naming, layering) that future code will assume.
- Touches enough surface area that "remember everything in your head" will fail.

Don't use it for one-shot tasks ("rename this function", "fix this bug", "add this prop"). Specs are heavyweight — overhead-justifying.

## Spec authoring uses plain English

When writing the spec content itself, use full English sentences. If the active output style is `wenyan-full`, **escape it for spec content** — specs are durable, future readers (other agents, you weeks later) shouldn't have to decode wenyan to pick up the work. Progress narration to the user about the spec ("done, written 4 phase files") can stay in the active style; the artifacts inside `.sworm/spec/` are plain English.

## The three shapes

Three shapes serve three patterns of work. Pick one during the interview based on the work's structure. All three use the same §-section vocabulary so a reader switching shapes doesn't re-orient.

### A. Phased multi-file
For sequenced work where order matters and each phase blocks the next.

```
.sworm/spec/<name>/
├── todo.md                    — index, decisions (§C), invariants (§V), phase list, final state
├── conventions.md             — cross-phase rules (only if 3+ phases share rules)
├── phase-0-<slug>.md          — own §T tasks, §B bugs, acceptance, risks
├── phase-1-<slug>.md
└── phase-N-<slug>.md
```

See `references/phased-shape.md`.

### B. Ticketed multi-file
For independent work items that can land in any order.

```
.sworm/spec/<name>/
├── todo.md                    — index, context (§G/§C/§V), ticket table (§T)
├── ticket-1-<slug>.md
└── ticket-N-<slug>.md
```

See `references/ticketed-shape.md`.

### C. Light single-file
For small initiatives that don't need multiple files but still want a durable, structured plan.

```
.sworm/spec/<name>/
└── SPEC.md                    — every section in one file
```

See `references/light-shape.md`.

Choose **phased** when there are hard dependencies. Choose **ticketed** when items are roughly parallel. Choose **light** when the whole spec is small enough to read top-to-bottom in 60 seconds — typically 1–3 PRs of work, no cross-phase invariants worth hoisting.

## Section schema (all shapes)

Every spec uses these section names, regardless of shape. The shape decides whether each section gets its own file or sits as a heading in `todo.md` / `SPEC.md`.

- **§G — Goal.** What this work is, why it exists, what's true after it ships. One paragraph.
- **§C — Constraints.** Locked decisions from the interview, out-of-scope items. Bullet list. Each bullet: WHAT was decided + brief WHY.
- **§I — Interfaces.** Touched files, public surfaces, API contracts that change or get introduced. Bullet list with paths.
- **§V — Invariants.** Cross-cutting rules every phase / ticket respects. The "what must remain true" list. Bullet list. Each invariant is testable (a grep, a type-check, a smoke step).
- **§T — Tasks.** The work itself. Pipe table: `| id | status | deps | summary | acceptance |`. In phased shape, each phase file holds its own §T table. In ticketed shape, `todo.md` holds the master table. In light shape, `SPEC.md` has one §T.
- **§B — Bugs.** Failures discovered during execution that aren't part of the original plan. Pipe table: `| id | severity | discovery | fix-target |`. Backprop appends rows here automatically (see `references/backprop.md`); resolution either promotes the lesson to §V or closes silently.

## The interview — do this first, every time

Before writing any file, ask the user clarifying questions. This is non-negotiable. A spec written from a one-line prompt will be vague, and a vague spec is worse than no spec because it implies false confidence.

Group your questions and ask in batches — don't drip-feed. The full question bank lives in `references/interview-checklist.md`. The opening pass should at least cover:

**Shape selection (decide first)**
- Sequenced or parallel? Single file or multi? "I'm going to make this a [phased / ticketed / light] spec — sound right?"

**Scope & shape**
- End state. Out-of-scope (more valuable than in-scope — prevents drift).
- Single coherent change vs sequence; if sequence, what blocks what.

**Decisions to lock**
- Library, naming, layering choices that should be decided **once** and respected by every phase / ticket.
- CLAUDE.md rules that need updating — list them.

**Risk & blast radius**
- Failure mode if a phase / ticket ships broken.
- Behavior-preserving vs intentional behavior change — flag every change explicitly.
- Migration steps for existing state.

**Surrounding context**
- Predecessor work, stakeholder constraints, parallel work, deadlines, freezes.

End the interview with: *"Anything else I should bake in before I write the spec? Once I write it, I'll treat it as load-bearing."*

The user's "no, that's it" is your signal to start writing. Until then, keep asking.

## Writing principles

These are what make a spec load-bearing rather than decorative.

- **Concrete over abstract.** "Rename `legacy` → `dev` in `tokenManager.ts:6` and 4 other sites" beats "clean up auth naming". File paths, line numbers, exact greps.
- **Verifiable acceptance.** Every acceptance bullet should be checkable with a command, a grep, or a manual smoke step. "Code is clean" is not acceptance; "`grep -rn 'as PatientId' src/` returns 0 hits" is.
- **State the why.** Each phase / ticket opens with the rationale. Future-you forgets why.
- **Flag behavior changes loudly.** A phase claiming "no behavior change" that secretly changes behavior is the worst failure mode.
- **Out-of-scope is sacred.** The list of "things tempting to do here but deferred" prevents scope creep mid-implementation.
- **Date the document.** Specs decay. A reader needs to know how stale it is.
- **Link forward and back.** Predecessor links matter; phase N references "see phase N+2 for X cleanup".
- **No PHI / no secrets.** Specs are checked in. Treat them like code.

## Comment / formatting conventions inside the spec

- Markdown only. Code blocks fenced with language hints.
- Checkboxes (`- [ ]`) for trackable items; markdown table for §T and §B.
- Don't use emoji. Don't use horizontal rules as decoration. Section dividers are H2s, named with the §-prefix (`## §G — Goal`).
- File-path mentions use backticks (`src/lib/foo.ts:42`).

## Optional: export §T to beads

After writing the spec, offer to export §T tasks as beads issues so the ready queue is graph-aware. This is opt-in, not automatic. See the `beads` skill's `references/integration.md` for the export protocol (one `bd create` per row, `bd dep add` mirroring deps, IDs round-tripped back into §T).

## Workflow

1. **Acknowledge the request and start the interview.** Don't write the spec until the user has clarified scope.
2. **Read the project's existing specs first.** Match their naming and structure. If `.sworm/spec/` doesn't exist yet, create it.
3. **Propose shape and name.** Tell the user: "I'll create `.sworm/spec/<kebab-case-name>/` as a [phased / ticketed / light] spec". Wait for confirmation if shape is non-obvious.
4. **Write the index file first.** `todo.md` for phased/ticketed; `SPEC.md` for light. Get §G/§C/§V right before drafting individual phase / ticket files.
5. **Write phase / ticket files** if the shape calls for them. Each one self-contained.
6. **Cross-link.** Update the index with relative links; each file's "out of scope" should reference where the deferred work lives.
7. **Show the user the structure** when done — list of files, one-line summary each. Offer to walk through any of them. Offer the beads export.

## What "no compromises" means

The user explicitly wants this skill to produce specs the agent can reference *without re-asking*. That means:

- If you're unsure whether something belongs in this phase or the next — **ask**, then write the answer down. Don't punt with "TBD".
- If you spot a decision the user didn't articulate — **surface it**, get an answer, lock it in §C.
- If a phase has a footgun (rename collision, persist version bump, build-tooling gotcha) — **document the risk** even if it feels paranoid.
- If a piece of work can't be specified yet (genuinely depends on a result from an earlier phase) — say so explicitly, with the trigger condition for revisiting: *"Re-evaluate after Phase 2 lands; the schema shape will determine whether we need a separate migration step."*

The cost of an extra question now is one minute. The cost of a missed decision is an hour of re-derivation in a future session that's already running on fumes.

## Reference files

- `references/phased-shape.md` — full skeleton for phased multi-file specs.
- `references/ticketed-shape.md` — full skeleton for ticketed multi-file specs.
- `references/light-shape.md` — full skeleton for single-file `SPEC.md`.
- `references/interview-checklist.md` — the question bank to draw from.
- `references/backprop.md` — the failure-to-§B-to-§V protocol that `work-spec` follows.
