---
name: work-spec
description: Execute a spec authored under `.sworm/spec/<name>/` — drive it from the first unchecked task to the last without re-litigating decisions. Use when the user says "work the spec", "start the spec", "execute this spec", "implement phase N", "/work-spec", or names a `.sworm/spec/<name>/` directory and asks you to make it real. Also trigger when the user references a spec by phase or ticket and wants implementation rather than discussion. The skill makes the agent a conscientious executor: read the whole spec, plan once, work continuously, parallelize independent work via specialized subagents, reuse the existing codebase, refuse over-engineering, and only halt on a true blocker.
---

# work-spec

Execute a spec from `.sworm/spec/<name>/`. The spec already settled the decisions; your job is to land the code, not re-decide the architecture. Stop only on a true blocker.

A "true blocker" is narrow:
- A decision the spec genuinely doesn't cover and you'd be guessing wildly (not a small judgment call).
- Missing access (a credential, a service you can't reach, a file that doesn't exist where the spec says it should).
- A direct contradiction between two parts of the spec where guessing wrong is destructive.
- A user request that would require destructive action you're not authorized to take (force-push, drop a table, rewrite shared history).

Anything else — small naming, ordering of two safe edits, whether to inline vs extract — make the call yourself, note it briefly, keep moving.

## What to do, in order

### 1. Locate and read the whole spec

The user names the spec (e.g. "work the inventory-screen-replacement spec") or you infer it from `.sworm/spec/`. Read **every file** in the spec directory:

- `todo.md` (phased / ticketed) or `SPEC.md` (light) — the index, locked decisions, §V invariants, task list, acceptance.
- `conventions.md` if present — cross-phase rules.
- Every `phase-N-*.md` or `ticket-N-*.md` file.
- Any other `.md` in the directory (notes, references).

Don't skim. The entire point of the spec was to capture decisions you would otherwise re-derive. Skipping a phase file means relitigating a settled question. Use the Read tool on each file; do not delegate this read to a subagent — you, the orchestrator, need the full picture.

### 2. Detect the spec shape

Three shapes (per `spec` skill):

- **Phased** — `todo.md` exists; multiple `phase-*.md` files. Work proceeds phase-by-phase in numeric order.
- **Ticketed** — `todo.md` exists; multiple `ticket-*.md` files. Work proceeds by ready-queue (priority + dependencies), not file order.
- **Light** — only `SPEC.md` exists. Work proceeds through `§T` rows in dependency order.

Shape detection drives task selection. Don't guess; check the directory.

### 3. Establish current state

Before touching code:

- `git status` and `git log -5 --oneline` — know what's already in flight.
- Cross-reference the spec's acceptance and §T statuses with the actual repo. A `closed` task in §T should already be done in code; if not, the spec is stale and you flag that to the user.
- Run `grep` on the spec's verification commands (acceptance bullets often contain literal greps) to learn what's already true.
- If `.beads/` exists at repo root, run `bd list --label spec:<spec-name> --json` to see whether the spec has been exported. If yes, beads is the source of truth for §T status going forward.

This step prevents you from re-doing finished work or, worse, undoing it.

### 4. Build a task list

Use TaskCreate to mirror the spec's structure.

- **Phased**: one task per phase, in spec order. Mark the first as `in_progress`.
- **Ticketed**: one task per ticket; ordering uses the ready queue (see step 5).
- **Light**: one task per §T row; ordering uses the ready queue.

If a phase contains many sub-tasks (e.g. `1.1`, `1.2`, `1.3`), keep them as a single phase task — don't fragment. The phase file is your work unit. Within a phase, use parallel tool calls for independent edits.

### 5. Pick the next unit of work

**If beads has the spec exported (`.beads/` exists, issues labeled `spec:<spec-name>`):**

```fish
bd ready --json --label spec:<spec-name> --limit 1
bd update <id> --claim
```

`bd ready` already understands priority, dependencies, and status. Use it. Don't re-derive ready logic in markdown.

**If beads does not have the spec exported:**

- Phased: next phase whose checkbox is `[ ]` and whose pre-reqs are all `[x]`.
- Ticketed: next §T row whose `status` is `open` and whose `deps` are all `closed`.
- Light: next §T row in the same way.

Either way, plan the run sequentially through the picked unit; don't pause for user check-in unless a true blocker surfaces.

### 6. Execute the unit

For each phase / ticket / task:

1. Re-read the relevant file (phase / ticket file, or the §T row in `SPEC.md`) to refresh detail in working memory.
2. Identify which sub-tasks are independent and can be done in parallel vs. sequenced. ("create file X" followed by "import X in Y" is sequential; two unrelated file creations are parallel.)
3. Make the edits using `Edit` / `Write` directly. Use `Bash` for codemods (`sed`, `grep -l ... | xargs ...`) when the change is mechanical and applies to many files.
4. After the unit's code lands, run its acceptance checks — every bullet in its `Acceptance` section. Most are one-shot bash (`./gradlew compileJava`, a `grep` that should return zero hits, a type-check). Run them. If a check fails, switch to backprop (step 8); don't move on with a failing acceptance.
5. Update the unit's status: phase checkbox `[ ]` → `[x]` in `todo.md`; ticket §T status `open` → `closed` in `todo.md`; light-shape §T status `open` → `closed` in `SPEC.md`. If beads is the source of truth, also `bd close <id> -r "<one-line summary>" --suggest-next`.
6. Mark the TaskCreate item completed and the next one in_progress.

Don't pause for user check-in between units. The spec already authorized the sequence.

### 7. Parallelize with specialized subagents when it pays

Subagents earn their slot when:

- The work is research-heavy and would burn the orchestrator's context (broad codebase exploration, doc lookups → use the `Explore` agent).
- The work is in a domain where a specialist agent exists in this project (frontend, db, infra, mod-platform, etc.) — check the available agent list and `.claude/agents/` for current names rather than assuming.
- Two phases / tickets truly don't depend on each other and you want them landing in parallel — spawn one subagent per independent track in the same turn.

Subagents do **not** earn their slot for trivial edits in the same file, or for sub-tasks within a single phase that are tightly coupled. Don't pay agent overhead for work you can do faster directly.

When you do delegate to a subagent, brief it like a colleague who hasn't seen this conversation: tell it which spec file to read, what unit it owns, what files it must edit, and the acceptance criteria it has to pass. Tell it to *not* expand scope. End the brief with: "Stop and report only on a true blocker; otherwise complete the unit and verify acceptance."

### 8. Backprop when a verification fails

When an acceptance / verification command fails, follow the backprop protocol (full detail in `spec/references/backprop.md`):

1. **Append to §B** in the active phase / ticket / spec file:
   ```markdown
   | <id> | <severity> | <where it failed + failing command> | <fix-target unit> |
   ```
2. **Create a beads bug** (if `.beads/` exists) so the failure outlives this conversation:
   ```fish
   bd create "<one-line title>" \
     --type bug -p <0|1> \
     -d "Failing command: <cmd>\nDiagnosis: <root cause>\nSpec: <spec-name>\nUnit: <T.id or phase>" \
     --deps "discovered-from:<unit-bd-id>" \
     --labels "spec:<spec-name>,backprop"
   ```
   Use the returned ID in §B's `id` column.
3. **Diagnose the root cause** — read the failing output, the relevant files, adjacent code.
4. **Land the fix.** Re-run the failing command; confirm green. Don't tick anything as done until the verification itself passes.
5. **Decide: promote or close local.**
   - General lesson (every future phase / spec in this repo benefits) → add a row to §V; close the beads bug `-r "promoted to §V: <rule>"`. If the rule belongs in CLAUDE.md, note it in `todo.md`'s "CLAUDE.md updates" section for the active phase to apply.
   - Local fix (only matters for this code site) → mark the §B row resolved (or remove); close the beads bug `-r "fixed; local"`.

### 9. Quality bar — reuse, don't reinvent

The deeper the spec, the more tempting it is to drop in fresh abstractions. Resist. Before writing a new helper, type, or service:

- `grep` for similar names and patterns. If a util already does 80% of what you need, extend it, don't duplicate.
- Check the spec's `conventions.md` (or §V) for a designated lib/util/store pattern — use it.
- Inspect neighbors of the file you're editing. Match the existing layering (e.g., if features live under `feature/<name>/`, drop yours there).

Before introducing a new abstraction (interface, base class, generic helper), ask: *does it have at least three concrete callers right now?* If not, inline. Premature abstraction is the most common spec-execution failure — agents see a phase named "create the registry" and over-engineer it. The spec authorized the registry; it did not authorize a five-method base interface. Land the smallest thing that satisfies the unit.

### 10. Recognize over-engineering as it happens

Watch for these smells in your own work and pull back:

- A class with one method and one caller — should it be a function?
- A type alias that wraps a single primitive once — does the alias add real safety, or just noise?
- A config object with all defaults — does the call site ever pass a non-default?
- A wrapper around a stdlib function that adds nothing — delete the wrapper.
- "Future-proofing" hooks for a use case the spec explicitly defers — defer with the spec.

The spec's "Out of scope (later phases)" section is your shield against this. If you're about to add code that only matters for an out-of-scope use case, don't.

### 11. Don't ask, decide

Examples of decisions to make and move on:

- Spec says "rename to `dev`"; one call site has a slightly different name (`legacyToken` instead of `legacy`). Rename it analogously and note in the unit summary.
- Spec specifies one verification grep but the file has been renamed since. Adjust the grep to the new path and run it.
- A comment in the existing code disagrees with the spec. The spec is the source of truth for new work; update the comment.
- A package version mismatch the spec didn't anticipate. If the upgrade is safe per package docs, take it. If risky, stop.

The decision is part of the work. Note non-obvious calls in your unit summary at the end so the user can sanity-check.

### 12. Halt only on a true blocker

True blocker is defined at the top of this file. If you do hit one:

1. Create a P0 beads issue (if `.beads/` exists):
   ```fish
   bd create "BLOCKER: <one-line>" \
     --type bug -p 0 \
     -d "<full blocker context: phase, sub-task, what failed, options considered>" \
     --labels "spec:<spec-name>,blocker"
   ```
2. Surface to the user: phase + sub-task you were on, the specific blocker, two or three concrete options if relevant, the new beads ID, and what you'll do once resolved.

Don't halt to confirm a phase the spec already authorized.

### 13. Final pass — clean up the spec

After the last unit:

- Update `todo.md` / `SPEC.md`: every checkbox `[x]`, every §T row `closed`, overall acceptance section walked through.
- Run the spec's overall acceptance commands top to bottom.
- If the spec has a `phase-N-cleanup.md`, run its grep checks and smoke checklist.
- Summarize to the user: which units landed, any decisions you made, any acceptance items that need a manual smoke test you couldn't run (e.g. in-game UI checks), and a one-line state-of-the-codebase note.

If a CLAUDE.md edit was assigned to a unit you completed, verify it's actually in the file. Specs commonly have doc edits that get forgotten under the code edits.

## Working style

**Pace.** Don't narrate every tool call. One sentence at the start of each unit saying which unit, what it does. One short sentence per non-obvious decision. End-of-spec summary covers the whole run. Silent tool work between announcements is fine.

**Failures.** When a verification command fails, run backprop (step 8) — diagnose, land fix, decide promote-or-local. Do not bypass with `--no-verify`, do not skip a check, do not lower the bar. The acceptance criteria are the spec's contract.

**Git hygiene.** Don't commit unless the user asked. The spec is for code; the commits are a separate user decision. If the user did ask for commits, commit per unit with a clear message: `<type>(<scope>): land <unit> — <one-line summary>`.

**Context discipline.** Read what you need; don't bulk-Read large vendor or generated files. If you need to find something, prefer `grep` / `Grep` over reading whole trees. Use the `Explore` agent for genuine codebase-wide investigation.

## Examples

**User:** "work the inventory-screen-replacement spec"

You:
1. Read `.sworm/spec/inventory-screen-replacement/todo.md` plus every phase file.
2. Detect shape: phased.
3. `git status`; check beads for `spec:inventory-screen-replacement` issues; confirm Phase 0 not yet done.
4. TaskCreate with one task per phase.
5. Phase 0 in_progress: create the two new files, edit the screen, run `./gradlew compileJava`, run the acceptance greps. Tick `todo.md`. Close any beads issues for Phase 0 with `--suggest-next`.
6. Phase 1 in_progress: same pattern. Continue through Phase 4.
7. Final summary: phases landed, one judgment call you made, any in-game checks the user should run.

**User:** "do phase 2 of inventory-screen-replacement"

You:
1. Read the spec index + phase 2 + conventions.md.
2. Confirm Phase 0 and Phase 1 are landed (read code, not just checkboxes).
3. If they aren't, surface that to the user — don't silently regress prerequisites.
4. Otherwise execute Phase 2 end-to-end.

**User:** "run the auth-rewrite spec but skip the migration phase, the team is handling that"

You:
1. Read the whole spec (you still need full context).
2. Note the skip; don't touch the migration phase, don't tick its box.
3. Land all other phases.
4. Summary explicitly notes the migration phase is unowned by you.

**User:** "work the small-cleanup spec" (light shape, no beads export)

You:
1. Read `.sworm/spec/small-cleanup/SPEC.md`.
2. Detect shape: light.
3. Walk §T rows in dependency order; for each, claim, edit, run acceptance, mark closed.
4. If any verification fails, run backprop (step 8) before moving on.
5. Final summary plus the closed §T table.

## Anti-patterns

- Reading only `todo.md` / `SPEC.md` and skimming phase / ticket files — you'll miss locked decisions and reinvent them.
- Stopping after each unit to ask "shall I continue?" — the spec already said yes.
- Spawning a subagent per sub-task — overhead drowns the work.
- Adding "while we're here" cleanups not in the spec — file follow-ups instead (beads issue, or §B row if the cleanup is in-scope).
- Marking a checkbox `[x]` without running its acceptance check — the box is a claim, back it up.
- Treating the spec as a suggestion when the code disagrees — the spec is the authority for new work; reconcile by changing the code, not the spec. (Backprop handles the case where the *spec* learned something wrong.)
- Asking permission to make a small naming or ordering call — make it.
- Bypassing backprop ("the test was flaky, moving on") — if it failed, diagnose. Flake-diagnosed-as-flake gets a §B row noting the flake; flake-not-actually-a-flake gets a real fix.
- Re-implementing `bd ready` logic in markdown when beads is available. Call the binary; trust it.
