---
name: spec-check
description: Read-only drift report against a `.sworm/spec/<name>/` spec. Runs the spec's acceptance / verification commands, checks §V invariants against the current code, and reports violations. Never mutates files. Use when the user says "check the spec", "is the spec still accurate", "what's drifted from the spec", "drift check", "/spec-check", or after a long-running spec to see what's slipped. Companion to `spec` (authoring) and `work-spec` (executing). The output is a single drift report — fix nothing automatically; that's `work-spec`'s job.
---

# spec-check

Run the spec's invariants and acceptance against the live repo. Report what's drifted. Touch nothing.

This skill exists because specs decay. Rules in §V get violated by tangential PRs. Acceptance commands fail because the codebase moved on. Without a drift check, the spec turns into stale aspiration. With one, you can see exactly which assumptions still hold and which need updating before more `work-spec` runs land on a wrong foundation.

## When to trigger

- "check the spec" / "is the spec still accurate"
- "drift check" / "what's slipped"
- `/spec-check` invocation
- After a long pause in spec work (a week+, or after a major external refactor)
- Before resuming `work-spec` on a partially-done spec
- As a CI step (the user adds `spec-check` to a workflow)

## Hard rule: read-only

Spec-check **never edits files**. Not the spec, not the code, not CLAUDE.md, not even to mark a §B row. Output is a markdown report. The user (or a follow-on `work-spec` invocation) decides what to fix.

If you're tempted to "just fix this small thing while we're here", stop. That's `work-spec`'s job. The drift report's value is its honesty about the gap; if you start closing the gap silently, the user can't trust the next report.

## What to check

Read the spec end-to-end first. Then run, in order:

### 1. Acceptance commands

For phased: every phase's `Acceptance` section + the spec-wide `Acceptance` section in `todo.md`.
For ticketed: every closed ticket's `Acceptance` section + the spec-wide section.
For light: the `Acceptance` section in `SPEC.md`.

For each acceptance bullet that's a runnable check (a `grep`, a type-check, a build command):
- Run it.
- Record exit status and the actual output.
- Compare against the expected output stated in the bullet.

Skip bullets that are manual smoke tests; list them as "manual — verify yourself" in the report.

### 2. §V invariants

For each invariant:
- If the bullet has an inline verification (`Verify: <command>`), run it.
- If it doesn't, attempt the verification by running the most-natural grep / type-check / lint based on the rule. If you can't, list the invariant as "no automated check; manual review required".
- Record any failures with the relevant file path / line / count.

### 3. §T task status

For phased / ticketed / light: walk every §T table.
- Tasks marked `closed` should have their acceptance still passing. If a closed task's acceptance now fails, that's drift — flag it.
- Tasks marked `open` are skipped — they're not done yet, so failing isn't drift.
- Tasks marked `in_progress` are listed as "still in progress" without judgment.

If the spec has been exported to beads, cross-reference:
```fish
bd list --label spec:<spec-name> --json
```
Compare the spec's §T statuses with beads' statuses. Drift here means someone closed an issue without updating the spec (or vice versa).

### 4. §B bugs (if any unresolved)

List unresolved §B rows. These aren't "drift" exactly — they're known, captured failures — but the report surfaces them so the user sees the open bug count alongside the spec's overall health.

### 5. CLAUDE.md updates

If the spec's `todo.md` lists CLAUDE.md edits, check whether they actually landed in `CLAUDE.md`. Diff the expectation against reality; report missing edits.

## Output format

A single drift report printed to the terminal. Use the project-wide CLI line and card formats from `AGENTS.md` — never markdown tables (some agent CLIs do not render them). Status glyphs: `✓` pass, `✗` fail, `⊘` not run / manual.

```markdown
# spec-check: <spec-name>

**Spec shape**: phased | ticketed | light
**Last spec update**: <git log date of last edit to .sworm/spec/<name>/>
**Run on**: 2026-04-30

## Summary

<2-3 sentences. How healthy is the spec? "Acceptance: 12/14 passing. 1 invariant drifted. 0 unresolved §B." Or "Spec is fully aligned — no drift detected.">

## Acceptance

- ✓ Phase 1 · `tsc --noEmit` · clean
- ✗ Phase 2 · `grep -rn 'as Patient\|as Encounter' src/` · 3 hits in `src/legacy/*.ts`
- ✓ Spec-wide · `pnpm check:fix` · clean
- ⊘ Phase 3 · manual smoke: <description> · not automated, verify yourself

## Invariants (§V)

- ✓ §V.1 · All API boundaries use valibot · 14/14 handlers have schemas
- ✗ §V.2 · No `as <Type>` casts of unknown values · 3 hits introduced since last check; see below

### §V.2 violations
- `src/legacy/handlers/payment.ts:42` — `as PaymentMethod` on unparsed JSON
- `src/legacy/handlers/payment.ts:88` — same pattern
- `src/services/billing.ts:201` — `as unknown as Customer` cast added in commit `<sha>`

## §T status drift

<Only listed if spec ↔ code or spec ↔ beads disagree. One card per drifted task.>

── Phase 2 / T.3 ─────────────────
Spec status:  closed
Code reality: acceptance fails (see above)
Beads status: open (`bd-c1d4`)

## Open §B bugs

<Unresolved bugs from the spec's §B tables.>

- `bd-a3f8` · required · discovered: Phase 2 acceptance grep · fix-target: Phase 3

## CLAUDE.md edits expected

- ✓ landed · Drop "<old rule>" (per Phase 1)
- ✗ not in CLAUDE.md · Add "<new rule>" (per Phase 0)

## Verdict

Healthy | Drifted (small) | Drifted (significant) | Stale — needs spec rewrite

<One-paragraph recommendation. "Drift is small — run `work-spec` against Phase 3 to address the 3 invariant violations and pick up §B bd-a3f8." Or "Spec is stale — major API surface from §I has been replaced by a different design; recommend a spec rewrite or supersede.">
```

## When drift is acceptable

Not all drift is a problem. Some patterns are normal:

- **In-progress tasks** with failing acceptance — that's the definition of in-progress.
- **Manual smoke tests** that haven't been re-run — note them in the report; don't pretend you can verify them.
- **Optional invariants** explicitly marked as aspirational in the spec — flag as "not yet enforced" rather than "drift".

The drift report's job is to tell the user *what* is true, not to judge whether each truth is good or bad. The user (or `work-spec` on its next pass) makes those calls.

## Modes

Default mode is full check (everything in `## What to check`). Two reduced modes:

- **`/spec-check fast`** — only acceptance, skip §V deep checks. For quick pre-PR reality check.
- **`/spec-check invariants`** — only §V, skip acceptance. For "did anything I just merge break a cross-cutting rule".

## Workflow

1. **Locate the spec.** User names it; or scan `.sworm/spec/` if exactly one spec exists; or ask.
2. **Read every file in the spec directory.** Don't skim. The §V invariants and acceptance bullets are spread across phase files in phased shape.
3. **Run checks in order.** Acceptance first, then §V, then §T, then §B, then CLAUDE.md. Parallelize the runs where the commands are independent.
4. **Compose the report.** Fill the records with concrete file paths, line numbers, hit counts. "drift detected" without specifics is not useful.
5. **Surface the verdict + recommended next action.** The report ends with one sentence the user can act on.
6. **Never write back to the spec or codebase.** If the user says "fix it", switch to `work-spec`; if they say "update the spec", switch to `spec`.

## Anti-patterns

- Editing the spec or code during a check. The report's value is its honesty; mutation breaks that contract.
- Reporting "everything is fine" without actually running the checks. If you can't run something, say so explicitly.
- Treating §B bugs as drift. They're tracked failures, not drift; list them separately.
- Conflating spec-vs-code drift (this skill's job) with spec-vs-reality drift (e.g., the user changed their mind — that's an authoring concern, not a check).
- Recommending a fix you can't run. "Fix the §V.2 violations" is fine; "automatically refactor the legacy handlers" is not — that's the user's call.
