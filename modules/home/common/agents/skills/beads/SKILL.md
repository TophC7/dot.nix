---
name: beads
description: >
    Wrap the `bd` (beads) CLI for issue tracking with first-class dependency support.
    Use whenever the user mentions issues, tasks, bugs, the ready queue, blockers,
    or beads itself; whenever they ask "what's ready", "what's blocking X", "create
    an issue", "claim X", "close X", "link X to Y", "show issue X"; whenever they
    invoke `/bd:*` or `/beads`; and proactively when `work-spec` hits a true blocker
    or `adversarial-review` produces Blocking findings that should outlive the
    conversation. Beads is a graph-backed tracker — issues have hash IDs (`bd-a3f8`),
    dependency edges (`blocks`, `relates_to`, `parent`), priorities (P0–P4), and an
    audit trail. Every operation goes through the `bd` binary; never reimplement.
---

# beads

Beads is a real CLI (`bd`, in nixpkgs as `pkgs.beads`). It owns storage (SQLite + JSONL in `.beads/`), ID generation, the dependency graph, and the ready-queue computation. **Your job is to call it correctly and translate its JSON output back to the user.** Never re-derive `bd ready` logic in markdown.

If `bd` isn't on `$PATH`, stop and tell the user — don't try to substitute.

## When to trigger

Trigger whenever the user:
- creates / closes / claims / shows / lists issues, tasks, bugs, or epics
- asks "what's ready", "what's blocking X", "what's next"
- says "open a bug for X", "track this", "remind me to come back to X"
- invokes `/bd:*`, `/beads`, or pastes a `bd-` ID
- references the `.beads/` directory or `bd prime`

Also trigger proactively from sibling skills:
- `work-spec` hits a true blocker → create a P0 issue so the blocker survives the conversation.
- `adversarial-review` produces Blocking / Required findings → offer to emit them as P0 / P1 bugs.
- `spec` finishes authoring a `§T` task table → offer to export rows as beads issues with their `deps` mirrored.

## First-run setup (per repo)

Detect `.beads/` at repo root before any operation. If missing:

1. **Ask the user about visibility** before initializing. The choice is one-time per repo:
   - **Shared (default for repos the user owns):** `bd init` — issues commit to git and sync across machines/team.
   - **Stealth (default for repos the user doesn't own / contributes to):** `bd init --stealth` — beads files stay out of git via per-repo `.git/info/exclude` and Claude Code settings; useful when you can't push `.beads/`.
2. The **global** `bd prime` hooks (SessionStart / PreCompact) are already wired declaratively in `modules/home/common/agents/claude/default.nix` — **never run `bd setup claude` (no flag)**, it edits `~/.claude/settings.json` directly and gets clobbered on the next `home-manager switch`. For **per-project** hooks, `bd setup claude --project` is fine (it writes `.claude/settings.local.json`, which is local to the repo and not Nix-managed).
3. If the project doesn't yet have an `AGENTS.md` snippet, suggest running `bd onboard` so the project advertises its bd usage to other agents.

If `.beads/` exists, just use it. Don't re-init.

See `references/stealth-vs-shared.md` for the trade-off.

## The core surface

These are the operations Claude actually runs. The full `bd` command set is much larger; the cheatsheet captures the rest.

```fish
# Create
bd create "<title>" -p <0-3> --type <task|bug|feature|epic> [-d "<body>"] [--deps id1,id2]
bd q "<title>"                              # quick capture, prints just the new ID

# Read
bd ready --json [--limit N] [--priority N] [--type bug]    # unblocked open work
bd list --status open --json                               # bulk read
bd show <id> --json                                         # one issue + audit trail
bd dep tree <id>                                            # see what this transitively depends on

# Mutate
bd update <id> --claim                      # atomic: assignee → you, status → in_progress
bd update <id> --status <status> --notes "<note>"
bd dep add <child> <parent>                 # parent blocks child
bd dep relate <a> <b>                       # bidirectional informational link
bd close <id> -r "<reason>" [--suggest-next]
```

Always use `--json` when you'll parse the result. Render to the user using the CLI line or card format (see Output discipline below) — never echo raw JSON unless asked, and never a markdown table.

## Doing it right

- **Don't re-implement `bd ready`.** It already understands priority, type, dependencies, molecules, staleness. Calling it gives the right answer. Re-deriving in markdown gives the wrong one.
- **One bead per atomic concern.** Don't pack multiple findings into one issue body; create one bead per Blocking / Required item with `bd dep relate` for cross-links.
- **Preserve the chain.** When you create a bug discovered while working another issue, link them: `bd create "..." --deps discovered-from:<parent-id>`.
- **Atomic claim before work.** `bd update <id> --claim` is the source of truth that you (the agent) own this issue. Skip it and another agent can grab the same work.
- **Close with a reason.** `bd close <id> -r "<one line>"` — future-you reads the audit trail and needs the why.
- **Use `--suggest-next`** on close when working through a queue: it surfaces newly unblocked work without a separate `bd ready` call.

## Integration with sibling skills

`spec`, `work-spec`, `adversarial-review`, and the in-repo `.sworm/spec/` system have explicit hooks into this skill. The contract is one-way (those skills call into beads), and the seams are documented in `references/integration.md`. Don't extend other skills to write JSONL or shell out independently — go through `bd`.

## When NOT to use

- Single-conversation TODOs. Use `TaskCreate` for in-conversation tracking.
- Project memories (durable cross-conversation lessons). Those go to `~/.claude/projects/.../memory/` via the auto-memory system. Beads is for in-flight work.
- Shopping-list style notes. Beads has overhead — a graph for items without dependencies is wasted ceremony.

## Output discipline

User-facing output for any read is the project-wide CLI line format from `AGENTS.md` — never a markdown table (some agent CLIs do not render them):

```
- `bd-a3f8` · P0 bug  · open · Auth middleware token expiry off-by-one
- `bd-b7c2` · P1 task · open · Cover middleware with regression test  (deps: `bd-a3f8`)
```

Field order: `<id> · P<priority> <type> · <status> · <title>`, with secondary metadata (deps, labels, due dates) in a trailing `(...)`. Sort by `(priority asc, status, id)` unless the user asks otherwise. Always wrap `bd-` IDs in inline code so they're greppable.

For deeper inspection (`bd show`), use the card format from `AGENTS.md`: one card per issue, `Title:` / `Status:` / `Deps:` / `Description:` fields.

For writes, echo the resulting ID(s) on one line and stop:

```
Created bd-a3f8 (P0 bug). Run `bd show bd-a3f8` for details.
```

## References

- `references/cli-cheatsheet.md` — the full command surface with annotated examples.
- `references/integration.md` — how `spec`, `work-spec`, `adversarial-review` call into beads.
- `references/stealth-vs-shared.md` — when to commit `.beads/`, when to gitignore it.
