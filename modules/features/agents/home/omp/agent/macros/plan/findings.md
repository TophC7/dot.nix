---
name: Plan Findings
summary: Turn /cleanup or /review:adversarial findings into a vetted implementation plan
---

/plan read `local://findings.md` (the latest `/cleanup` or `/review:adversarial` report) and plan fixes for its `Confirmed` and `Unverified` findings. `Applied` items are done; `Refuted` items were disproved—do not reopen them unless the code says otherwise.

1. **Vet unverified & gaps first**: Check the code for every `Unverified` finding and every coverage gap to confirm or discard it. Trust `Confirmed` findings unless reading the code disproves them.
2. **Group by root cause**: Merge findings that share an underlying cause, seam, or caller chain into cohesive workstreams so we fix root causes rather than patching symptoms one ticket at a time.
3. **Weigh options & discuss**: Present the proposed workstreams briefly and use `ask` only for genuine design tradeoffs, behavioral choices, or scope boundaries—never ask per-finding "should we fix this?".
4. **Settle the plan**: Write a self-contained implementation plan with exact file paths, caller updates, verification checks, and all agreed decisions so it can execute directly in a fresh session.

Focus or exclusions: {{cursor}}
