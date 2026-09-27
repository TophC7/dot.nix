---
name: sworm-tasks
description: How to author, edit, and validate Sworm's per-project task config at `.sworm/tasks.json`. Use this skill whenever the user asks to add, edit, rename, remove, or troubleshoot a Sworm task; whenever they mention `tasks.json`, `.sworm/tasks.json`, the task launcher, the title-bar task menu, the command palette's task entries, or task tabs; and whenever they describe wanting to wire up a reusable terminal command (build, dev server, lint, typecheck, test) for the project. Also trigger when the user is starting a new Sworm project and needs a tasks file scaffolded.
---

# Sworm Tasks (`.sworm/tasks.json`)

Sworm reads per-project tasks from `<project>/.sworm/tasks.json`. The file is committed to the repo so the whole team gets the same launcher entries, command-palette items, and title-bar menu.

The Rust struct in `src-tauri/src/models/task.rs` is the source of truth for the schema. A JSON Schema is generated from it at runtime and registered against `**/.sworm/tasks.json` (see `src-tauri/src/services/config_schemas.rs`), so Monaco gives autocomplete and hover docs while editing the file. **If the schema needs to change, edit the Rust struct — do not hand-write JSON Schema.**

## File shape

```json
{
  "version": 1,
  "tasks": [
    {
      "id": "dev",
      "label": "Tauri Dev",
      "command": "bun app:dev",
      "singleton": true,
      "clearOnRerun": false,
      "icon": "play",
      "group": "serve"
    }
  ]
}
```

- Top-level keys: `version` (currently always `1`) and `tasks` (array).
- All task keys are **camelCase** in JSON (`clearOnRerun`, not `clear_on_rerun`).
- A missing file is treated as "no tasks" — never an error.

## TaskDefinition fields

| Field          | Type                  | Required | Notes                                                                                       |
| -------------- | --------------------- | -------- | ------------------------------------------------------------------------------------------- |
| `id`           | string                | yes      | Stable identifier. Keep URL-safe: letters, digits, dashes. Used as a state key.             |
| `label`        | string                | yes      | Display name for the tab and menus.                                                         |
| `command`      | string                | yes      | Runs through `$SHELL -c`, so pipes, globs, `&&`, quoting, env expansion all work.           |
| `cwd`          | string                | no       | Relative to project root (or absolute). Defaults to project root.                           |
| `env`          | object<string,string> | no       | Merged on top of the inherited project env (which already includes the Nix env if present). |
| `icon`         | string                | no       | Any Lucide icon name. Invalid names fall back to a default task icon.                       |
| `group`        | string                | no       | Free-form label. Tasks sharing a group cluster together in the launcher.                    |
| `singleton`    | boolean               | no       | Default `false`. If `true`, rerunning focuses the existing tab instead of opening a new one.|
| `clearOnRerun` | boolean               | no       | Default `false`. Clears scrollback on rerun. Only meaningful with `singleton: true`.        |
| `confirm`      | boolean               | no       | Default `false`. Prompts before running. Use for destructive or expensive commands.         |

## Variable substitution

Resolved by `TaskService::resolve` in `src-tauri/src/services/tasks.rs` against `command`, `cwd`, and every `env` value:

- `${workspaceFolder}` — absolute path to the project root.
- `${file}` — active editor file path; expands to empty string when nothing is open.
- `${env:NAME}` — value from the project env, falling back to the host process env, falling back to empty.
- Unknown `${...}` keys are left literal in `command`/`cwd` so typos stay visible (env vars are the exception — missing env names expand to empty, matching shell behavior).

## Common patterns

**Long-running serve task** — singleton + clearOnRerun keeps a single "Dev" tab that resets each time you restart it:

```json
{
  "id": "dev",
  "label": "Tauri Dev",
  "command": "bun app:dev",
  "singleton": true,
  "clearOnRerun": true,
  "icon": "play",
  "group": "serve"
}
```

**One-shot check** — no singleton, opens a fresh tab each run so you can compare outputs:

```json
{
  "id": "check",
  "label": "Typecheck",
  "command": "bun run check",
  "icon": "check",
  "group": "build"
}
```

**Run against the active file**:

```json
{
  "id": "test-file",
  "label": "Test current file",
  "command": "bun test ${file}",
  "icon": "flask-conical",
  "group": "test"
}
```

**Destructive — gate behind confirm**:

```json
{
  "id": "db-reset",
  "label": "Reset DB",
  "command": "rm -f ${workspaceFolder}/data.sqlite && bun run db:seed",
  "confirm": true,
  "icon": "trash",
  "group": "db"
}
```

## Authoring rules of thumb

- Keep `id` short and stable; users address it from the palette and other code may reference it as a state key. Renaming an `id` resets any per-task UI state.
- Put serve/dev tasks in `group: "serve"`, build/check tasks in `group: "build"`, tests in `group: "test"` to match existing conventions.
- Prefer `singleton` for any task you'd otherwise want to manually find-and-kill before restarting (servers, watchers).
- Combine `singleton: true` + `clearOnRerun: true` for "restart and start fresh" ergonomics; without singleton, `clearOnRerun` does nothing.
- Use `confirm: true` for `rm`, destructive db ops, force pushes, or anything that takes more than ~30s to undo.
- For Lucide icon picks: see https://lucide.dev/icons/ — names are kebab-case (`flask-conical`, `play`, `check`, `hammer`, `database`, `bug`, `terminal`).

## Editing and reload

The file is watched by `TaskService::watch` (notify crate). When `.sworm/tasks.json` is created, modified, or its parent `.sworm/` directory appears, the backend emits a `tasks-changed` event and the frontend store (`src/lib/features/tasks/state.svelte.ts`) refetches automatically. **No app restart is needed after editing the file.**

If a user reports "my new task isn't showing up":

1. JSON parse error — check the Sworm notifications panel (load failures surface as a notification) or run `jq . .sworm/tasks.json`.
2. Wrong key casing — JSON keys are camelCase; `clear_on_rerun` will be silently ignored.
3. Watcher missed an event — switching projects in the UI re-runs `tasks_list` and reloads, which is the cheapest manual nudge.

## When changing the schema itself

If a request requires a new field or removing one:

1. Edit `src-tauri/src/models/task.rs` — the doc comments on each field become Monaco hover tooltips, so write them user-facing.
2. Bump `version` semantics only if the change is breaking; additive optional fields don't need a version bump.
3. Update `TaskService::resolve` if the new field affects the spawn (command, cwd, env).
4. Run `cargo check` to confirm the schemars-generated schema still compiles.
5. Update this skill's table and examples to match.

The frontend type (`TaskDefinition` in `src/lib/types/backend.ts`) is generated from the Rust side, so don't hand-edit it.
