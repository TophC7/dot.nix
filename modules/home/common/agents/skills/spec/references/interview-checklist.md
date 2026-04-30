# Interview checklist

Question bank for the interview phase. Don't ask every question on every spec — pick the ones the user's prompt left ambiguous. Group questions and ask in batches.

The interview's job is to surface the decisions a future reader will assume have been made. A spec built from a one-line prompt makes those decisions silently and produces a worse spec than no spec at all.

## Ask order

Roughly: shape first → scope → decisions → risks → context. The further down the list, the more contingent on earlier answers.

## Shape selection (always ask first)

- Is this sequenced (each piece blocks the next) or parallel (items land independently)?
- Roughly how big — 1–3 PRs, or a multi-week initiative?
- Confirm shape: "I'll write this as a [phased / ticketed / light] spec — sound right?"

If the user says "I don't know yet", default to phased for sequenced unknowns and light for small unknowns. You can convert later (see `light-shape.md`'s migration section).

## Scope & end state

- "When this is done, what does success look like?" Push for observable properties, not aspirations.
- "What's explicitly **out of scope**?" Out-of-scope is more valuable than in-scope — it prevents drift mid-implementation. Ask twice if the user lists nothing.
- "Is this a single coherent change, or a sequence?" If sequence, "what blocks what?" Get the dependency graph.
- "Behavior-preserving, or are there intentional behavior changes?" If changes, list them now — silent behavior changes inside a "refactor" phase are the worst spec failure mode.

## Decisions to lock

These become §C entries.

- "Are there library, naming, or layering choices that should be decided **once** and respected by every phase / ticket?" Examples:
  - validation library (zod, valibot, ajv)
  - state management pattern
  - file/folder layout for new features
  - naming conventions for new symbols
  - test runner / fixture pattern
- "Are there CLAUDE.md rules that need updating to reflect the new convention?" Make a list — these get applied incrementally per phase.
- "Any version bumps or dependency changes that should land in a specific phase?"

## Risk & blast radius

These become §V invariants and Risks entries.

- "What's the failure mode if a phase / ticket ships broken?" silent runtime, type errors, data corruption, lost work. Different failure modes get different mitigations.
- "Which parts are migration-from-existing-state and need a backwards-compat or migration step?" Persisted data, URL shapes, public APIs, file formats.
- "Are there any persisted-state version bumps?" Localstorage, IndexedDB, sessionStorage, cookies — version bumps must be deliberate.
- "What downstream consumers / projects depend on the surfaces this spec touches?"
- "What CI / lint / type-check gates need to stay green per phase boundary?"

## Surrounding context

- "Is there a previous spec or PR this builds on?" Link it. Predecessor links matter; they tell the future reader where to look for the prior decisions this spec assumes.
- "Any deadlines, freezes, parallel work that conflicts?" Stakeholder constraints — code freezes, release branches, conflicting refactors elsewhere.
- "Anything you *wish* the codebase did differently that this spec is a chance to fix?" Often surfaces a §C decision that wouldn't have come up otherwise.
- "Who else might pick up this work?" If the answer is "another agent in a fresh conversation", the bar for spec thoroughness goes up.

## Suggestions you should surface (don't just take orders)

The interview isn't only Q&A — it's also a chance to push back and propose.

- **Spot opportunities the user didn't ask for.** "While we're touching this, X would be cheap to fix" or "this naming will collide with Y, propose Z".
- **Push back on under-specified scope.** "You said 'clean up auth' — there are four different things that could mean. Which?"
- **Propose phase boundaries.** "I'd split this into 3 phases because phase 2 depends on the new schema landing first. Sound right?"
- **Flag false-confidence terms.** "You said 'simple refactor', but it touches the auth boundary, which has these three downstream consumers. Want to scope those in or call them out as out-of-scope?"
- **Surface the obvious-but-unsaid.** "Should this also update CLAUDE.md?" almost always gets a "yes" the user forgot to say.

## End-of-interview check

End every interview with:

> *"Anything else I should bake in before I write the spec? Once I write it, I'll treat it as load-bearing."*

The user's "no, that's it" is your signal to start writing. Until then, keep asking.

## When the user is impatient

If the user pushes back on the interview ("just write it", "I'll figure it out as we go"), respond with:

> "I can write it now, but the spec will be shallow — fine for a single conversation, less useful as something to come back to in a week. Worth 5 minutes of questions to make it durable, or do you want the shallow version?"

Then honor whichever they choose. Don't argue twice.

## What "thorough" looks like

A thorough spec interview produces:
- 5–15 §C entries (locked decisions).
- 3–8 §V invariants.
- A short list of out-of-scope items.
- Clear shape (phased / ticketed / light) and per-phase / per-ticket carving.
- A predecessor link if applicable.
- A list of CLAUDE.md edits the spec implies.

If the post-interview spec doesn't have most of these, the interview wasn't deep enough — go back and ask more.
