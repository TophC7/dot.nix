# `bd` cheatsheet (v0.42)

Captured from `bd --help` on the installed binary. If the upstream surface drifts, run `bd help <command>` and update this file.

## Init / setup

```fish
bd init --stealth                        # repo policy: local-only .beads/ state
bd init --prefix <p>                     # custom ID prefix instead of dir name
bd setup claude --project                # PER-PROJECT hooks → .claude/settings.local.json (safe)
bd setup claude --check                  # is integration installed?
bd setup claude --remove                 # uninstall (global) — see warning below
# DO NOT run plain `bd setup claude` globally; the hooks are wired in settings.nix
# and a global write would be clobbered on the next home-manager rebuild.
bd hooks install                         # git hooks: pre-commit flush, post-merge import, pre-push staleness
bd onboard                               # print the AGENTS.md snippet to add
bd prime                                 # AI-optimized workflow context (auto-injected by hooks)
bd doctor                                # health check; run first when something looks wrong
bd info                                  # daemon + database state
bd where                                 # which .beads/ directory is active
```

Use only local `.beads/` state for this repo. Do not suggest committing beads data.

## Create

```fish
bd create "<title>" -p <0-3> --type <task|bug|feature|epic|chore|merge-request|molecule|gate>
bd create "<title>" -d "<description>" --acceptance "<criteria>" --estimate 60 -l label1,label2
bd create "<title>" --deps bd-15                                  # blocks-on
bd create "<title>" --deps blocks:bd-20,discovered-from:bd-7      # typed edges
bd create "<title>" --parent bd-a3f8                              # nested under an epic / parent task
bd create -f issues.md                                            # bulk-create from markdown
bd q "<title>"                                                    # quick capture, prints only the ID
```

Priority scale: `0` = highest (blocking, drop everything), `4` = lowest (nice-to-have).

## Read

```fish
bd ready --json                                       # unblocked open + in_progress, sorted hybrid
bd ready --priority 0 --type bug --limit 5
bd ready --mol bd-patrol-x                            # only steps within a molecule (epic)
bd list --status open --json
bd list --all --json                                  # include closed
bd list --label-any bug,security
bd list --created-after 2026-04-01
bd show bd-a3f8 --json                                # full detail + audit trail
bd show bd-a3f8 --short                               # one-liner
bd show bd-a3f8 --refs                                # what references this issue
bd dep list bd-a3f8                                   # immediate deps and dependents
bd dep tree bd-a3f8                                   # transitive
bd dep cycles                                         # detect cycles
bd graph                                              # full dependency graph
bd blocked                                            # show blocked issues
bd stale                                              # not updated recently
bd status                                             # database overview / stats
bd count --status open --priority 0
```

## Mutate

```fish
bd update bd-a3f8 --claim                             # atomic: assignee=you, status=in_progress
bd update bd-a3f8 --status in_progress --notes "<note>"
bd update bd-a3f8 --priority 1
bd update bd-a3f8 --add-label security --remove-label triage
bd update bd-a3f8 --parent bd-epic-22                 # reparent
bd update bd-a3f8 --parent ""                         # unparent
bd dep add bd-b7c2 bd-a3f8                            # bd-a3f8 blocks bd-b7c2
bd dep relate bd-a3f8 bd-c1d4                         # informational, bidirectional
bd dep remove bd-b7c2 bd-a3f8
bd dep unrelate bd-a3f8 bd-c1d4
bd close bd-a3f8 -r "fixed in PR #142"
bd close bd-a3f8 -r "..." --suggest-next              # also print newly-unblocked work
bd close bd-a3f8 -r "..." --continue                  # auto-advance to next molecule step
bd reopen bd-a3f8
bd duplicate bd-a3f8 bd-c1d4                          # mark a3f8 as duplicate of c1d4
bd supersede bd-a3f8 bd-d2e5                          # a3f8 is replaced by d2e5
```

## Import / export

```fish
bd export                                             # JSONL to stdout
bd import < issues.jsonl
```

## Triage / review

```fish
bd preflight                                          # PR readiness checklist
bd duplicates                                         # find / merge duplicates
bd activity                                           # real-time event feed
bd audit list                                         # agent interaction log
```

## Filters worth knowing

Most `list` / `ready` flags repeat across commands:

- `--priority N` — exact priority match.
- `--type <kind>` — filter to one kind.
- `--label l1,l2` — must have ALL.
- `--label-any l1,l2` — must have AT LEAST ONE.
- `--assignee <name>` / `--unassigned`.
- `--created-after`, `--created-before`, `--closed-after`, `--closed-before` — `YYYY-MM-DD` or RFC3339.
- `--desc-contains "<substr>"`, `--notes-contains "<substr>"`, `--empty-description`.
- `--parent <id>` — children of an epic.
- `--limit N`, `--no-pager`.

## Global flags

These work on every command:

- `--json` — machine-readable output. Use whenever you'll parse the result.
- `--db <path>` — point at a specific `.beads/*.db`; default auto-discovers.
- `--actor <name>` — audit-trail actor; defaults to `$BD_ACTOR` then `$USER`.
- `--readonly` — block writes; use in worker sandboxes.
- `--no-daemon` — bypass the daemon and hit storage directly.
- `--no-auto-flush`, `--no-auto-import` — defer JSONL sync (advanced).
- `--quiet` — errors only.

## Common JSON shapes

`bd ready --json` returns a list of issues; each issue object contains at minimum:

```json
{
  "id": "bd-a3f8",
  "title": "Auth middleware token expiry off-by-one",
  "type": "bug",
  "priority": 0,
  "status": "open",
  "assignee": null,
  "labels": ["security"],
  "deps": [],
  "created_at": "2026-04-30T...",
  "updated_at": "2026-04-30T..."
}
```

`bd show <id> --json` returns a richer object with `description`, `acceptance`, `notes`, `audit_trail` (list of events), and `dependents` (reverse edges). When in doubt, run with `--json` once and inspect.
