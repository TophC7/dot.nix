# Ticketed shape — full skeleton

Use when the work is a collection of independent items that can land in any order. No hard sequencing; tickets are pulled by whoever has bandwidth. Section vocabulary matches phased and light shapes.

## Directory layout

```
.sworm/spec/<name>/
├── todo.md                    — index, context (§G/§C/§V), ticket table (§T)
├── ticket-1-<slug>.md
├── ticket-2-<slug>.md
└── ticket-N-<slug>.md
```

Naming rules:
- Spec directory: kebab-case noun phrase (`api-cleanup-followups`, `ds-migration-leftovers`).
- Ticket files: `ticket-<N>-<short-slug>.md`. Slug is 2-4 words, kebab-case, action-y (`fix-stale-cache`, `add-rate-limit`, `migrate-deprecated-endpoint`).
- Numbers are stable identifiers, not priority — once a ticket has number 3, it stays number 3 even if it lands last. Don't renumber.

## `todo.md` — annotated template

```markdown
# <Spec title>

**Started**: 2026-04-30
**Predecessor**: `<spec-name>` (if applicable, e.g. "follows the lib-refactor spec; cleanup work that didn't fit there")
**Shape**: ticketed

## §G — Goal

<One paragraph: what bucket of work this is, why it exists, what's true after every ticket closes.>

## §C — Constraints (locked decisions + out-of-scope)

- **<Decision area>**: <decision>. <why>.
- **Out of scope (entire spec):** <list>.

## §I — Interfaces (touched files / public surfaces)

<Files / surfaces touched across the spec. Each ticket's file lists its specific paths; this is the union.>

- `<path>` — touched by ticket-1, ticket-3.
- `<path>` — touched by ticket-2.

## §V — Invariants (cross-ticket rules)

<Rules every ticket respects. Tickets are independent in *what* they do, not in *how* they do it.>

- <Rule>. Verify: `<command>`.
- <Rule>. Verify: <manual check>.
- All tickets keep `tsc --noEmit` clean per ticket boundary.

## CLAUDE.md updates (apply incrementally per ticket)

<Edits to project CLAUDE.md, attributed to the ticket that makes them.>

- Add "<rule>" — per ticket-1.
- Update "<rule>" — per ticket-3.

## §T — Tickets

| id | status | priority | summary | file |
|----|--------|----------|---------|------|
| T1 | open | P1 | <one-line summary> | [ticket-1-<slug>.md](ticket-1-<slug>.md) |
| T2 | open | P2 | <summary> | [ticket-2-<slug>.md](ticket-2-<slug>.md) |
| T3 | open | P0 | <summary> | [ticket-3-<slug>.md](ticket-3-<slug>.md) |

<Sort visually by priority, but the `id` is stable. work-spec / beads consume this table for the ready queue.>

## Final state

<Concrete observable properties after every ticket closes. QA-style description.>

- All deprecated `/api/v1/*` endpoints removed.
- No `legacy*` symbols in `src/`.
- CLAUDE.md reflects the new conventions.

## Acceptance (overall)

- [ ] Every §T row has `status: closed`.
- [ ] `<spec-wide verification command>` succeeds.
- [ ] CLAUDE.md updated per the list above.
```

## `ticket-N-<slug>.md` — annotated template

```markdown
# Ticket N — <Title>

<One paragraph: what this ticket changes, why, and what's NOT changing.>

**Priority**: P0 | P1 | P2 | P3
**Blast radius**: <small / medium / large>
**Behavior change**: <"none" or explicit list>

## §T — Tasks

| id | status | deps | summary | acceptance |
|----|--------|------|---------|------------|
| TN.1 | open | — | <subtask> | <verification> |
| TN.2 | open | TN.1 | <subtask> | <verification> |

<For tickets that decompose into sub-tasks. For atomic tickets, this section can be one row.>

### TN.1 <Task title>

<Why. File paths. Concrete steps. Verification command.>

## Acceptance

- [ ] <observable, testable outcome>
- [ ] <grep returns nothing>
- [ ] <type-check passes>

## §B — Bugs (discovered during execution)

| id | severity | discovery | fix-target |
|----|----------|-----------|------------|

<Empty at start. Backprop appends rows here.>

## Risks

- **<Risk name>**: <description>. <detection>. <mitigation>.

## Out of scope (other tickets / future)

- <Thing>. (ticket-3 owns)
- <Thing>. (deferred to a later spec)
```

## When ticketed is the right call

- The work is a bag of independent improvements (post-refactor cleanup, deprecation removal, accessibility audit fixes).
- Two or more people / agents might pull tickets in parallel.
- Order doesn't matter except for priority.
- A "phase 1, phase 2" framing would be artificial — there's no genuine sequence.

## Anti-patterns

- **Pretending sequenced work is ticketed** to avoid writing phase files. If ticket-2 secretly depends on ticket-1's renames landing first, that's a phased spec wearing ticketed clothes. Use phased.
- **Renumbering tickets when one closes.** The numbers are stable identifiers; references to "ticket-3" in commit messages and PRs need to keep resolving. Closed tickets stay in the table with `status: closed`; new tickets get the next available number.
- **Tickets that secretly cross §V invariants.** If a ticket has to break an invariant to land, it's an architectural change — promote it to a phased spec or update §V deliberately, don't just ship it.
