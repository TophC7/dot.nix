# Catalog

Single source for Toph's workflow in **OMP, Claude Code, Codex, Antigravity, and
DSH**. Change shared prose here; change native rendering in `../home/<harness>`.
OMP prompt files are generated too, not a separate authoritative copy.

## Ownership and layout

```text
catalog/
├── default.nix             # Entry point: loads prompts, re-exports render helpers
├── lib/
│   ├── markdown.nix        # Reads `+++` TOML frontmatter + prompt text
│   ├── schemas.nix         # Shared JTD report schemas (review, decomplect)
│   └── render.nix          # withFrontmatter, render, schemaContract, mapTools
├── instructions/{soul,rules,caveman,ponytail}.md
├── agents/*.md             # Six review, four cleanup, decomplect, committer, pr
├── workflows/*.md          # review-adversarial, cleanup, decomplect, commit, pr
├── macros/*.md             # plan, phased-plan, plan-phase, ui-screens, pr-brent
└── readme.md
```

Each prompt is one Markdown file: its settings sit in `+++` TOML frontmatter,
then one blank line, then the prompt text. To change an agent, open that agent's
file. TOML rather than YAML because Nix parses it natively (`builtins.fromTOML`);
YAML would need a build-time parser. Adapters still emit whatever native format
each harness needs.

```markdown
+++
description = "Read-only /review:adversarial pass for architecture fit, ownership, boundaries, and seams"
role = "advisor"
tools = ["read", "grep", "glob", "lsp", "ast_grep"]
report = "incremental"

[output]
schema = "review"
scope = "Architecture Fit"
+++

You are the `/review:adversarial` Architecture Fit scout.
```

Frontmatter fields by kind:

- **Agents:** `description`, `role` (OMP model role), `tools` (OMP capability
  names), optional `report` (`incremental`/`terminal`) and `[output]` naming a
  schema in `lib/schemas.nix` plus its arguments. The loader resolves `[output]`
  to the JTD schema and defaults missing `output`/`report` to `null`.
- **Workflows:** `description`, `omp` and `claude` command paths, and
  `[dispatch]` with `batch` (agent list), `fanout` (agent), or `[dispatch.single]`
  (`agent`, `task`).
- **Macros:** `name` (display), `summary`, optional `skill` (Codex/Antigravity
  instruction replacing the draft).

Every loaded entry gets `id` (file stem), `name` (stem unless frontmatter sets
one), and `body`. Role-to-model mappings live in the adapters that need them
(`../home/claude`, `../home/antigravity`); Codex and DSH inherit the session model.

Bodies remain the original OMP text, byte-for-byte, except approved `{{tokens}}`.
Preserve wording, ordering, agent names, and macro display names rather than
rewriting a portable approximation.

Generated OMP output must match the original hand-written files. Only these
differences are allowed:

- `/commit` description is `Create a conventional commit from staged changes.`
- Caveman and Ponytail are static files (see Caveman and Ponytail below), not
  toggles.
- Frontmatter scalars may be quoted differently, but must remain YAML-equivalent.

OMP TypeScript extensions under `../home/omp/extensions/` stay hand-written.
`macros.ts` and the interactive decomplect plan-mode hook own runtime behavior.
`luna-priority.ts` stays OMP-only: it patches provider requests, not shared
workflow instructions.

## Helpers and placeholders

`default.nix` exports `soul`, `rules`, `caveman`, `ponytail`, `workflows`,
`agents`, `macros`, and the `lib/render.nix` helpers:

- `withFrontmatter fields body`: JSON-encoded YAML values, opening delimiter on
  line 1, one blank line before the body, and a final newline.
- `render vars label body`: replaces keys such as `"{{harness}}"`; throws if any
  `{{` remains. Adapters expand `{{dispatch}}` **first**, then remaining tokens,
  including tokens inside dispatched task text.
- `schemaContract schema`: final fenced `json` object matching the catalog's JSON
  Type Definition (JTD), with nothing afterward.
- `mapTools harness table caps`: concatenates native capability mappings; `[]`
  means intentionally unavailable, while an unmapped capability throws.

| Approved tokens | Adapted meaning |
| --- | --- |
| `{{harness}}` | Soul heading/identity, signature, Ponytail's Soul reference |
| `{{args}}` | OMP/Claude `$ARGUMENTS`; skill-invocation text elsewhere |
| `{{dispatch}}`, `{{parallelBatches}}` | Native batch, single-agent, and subsystem-owner dispatch |
| `{{prRef}}`, `{{internalUris}}`, `{{note}}` | OMP references/URIs/scratch notes versus foreign URLs/numbers/files |
| `{{askOffer}}`, `{{askRepo}}`, `{{askBatch}}`, `{{askDecisions}}` | Native question tools or direct questions to Toph |
| `{{planGate}}`, `{{planSubmit}}` | Native plan-mode entry requirement and proposal submission |
| `{{report}}` | OMP native reporting versus foreign fenced JTD JSON |
| `{{commitStep}}`, `{{prCreate}}` | OMP commit/PR tools versus temporary message/body files and `git`/`gh` |
| `{{fastSubagent}}` | OMP `@smol`, Claude `haiku`, fastest available model elsewhere |

## Native files and dispatch

All paths below are relative to `~`. Review launches six dedicated agents; cleanup
launches four; decomplect fans out one `decomplect-scout` per discovered owner;
commit and PR dispatch `committer` and `pr`.

| Harness | Instructions | Workflow and agent files | Native dispatch |
| --- | --- | --- | --- |
| OMP | `.omp/agent/AGENTS.md`, `RULES.md` | `.omp/agent/commands/*.md`, `agents/*.md` | One parallel `task` batch; explicit agent for singles |
| Claude Code | `.claude/CLAUDE.md` | `.claude/commands/**`, `.claude/agents/*.md` | Parallel `Agent` calls in one message, named `subagent_type`; unavailable scopes run inline |
| Codex | `.codex/AGENTS.md` | `.codex/skills/*/SKILL.md`, `.codex/agents/*.toml` | `spawn_agent` with named `agent_type`, collect all through `wait_agent` |
| Antigravity | `.gemini/GEMINI.md` | `.gemini/config/skills/*/SKILL.md`, `.gemini/config/agents/*.md` | One `invoke_subagent` call with a `Subagents` array and named `TypeName` |
| DSH | `.dsh/AGENTS.md` | `.dsh/skills/*/SKILL.md`, relevant agent bodies appended under `Agent instructions` | Concurrent `subagent` calls; each prompt begins with that agent's instructions |

OMP and Claude expose `/review:adversarial` (Claude file
`commands/review/adversarial.md`). Skill names cannot contain `:`, so Codex uses
`$review-adversarial` and Antigravity and DSH use `/review-adversarial`. Other
workflow names are cleanup, decomplect,
commit, and pr. Codex skills deliberately remain under `.codex/skills`:
DSH also reads `.agents/skills`, so the shared root would leak Codex-only dispatch.

### Output and tool parity limits

OMP retains native `output` schemas and incremental `yield` reporting for the six
review agents; decomplect returns a terminal `yield`. Other harnesses receive the
same JTD as an instruction to finish with one fenced JSON object. That is a prompt
contract, not native schema enforcement or incremental events. Cleanup agents,
committer, and PR have no output schema.

- Claude scouts expose `Read`, `Grep`, `Glob`; writable agents map `bash` to
  `Bash` plus `Write`. Antigravity maps to `view_file`, `grep_search`,
  `find_by_name`, `list_dir`, `run_command`, and `write_to_file`.
- Both adapters intentionally omit OMP `lsp`, `ast_grep`, and `github`
  capabilities. PR creation uses `gh` with an explicit base and a temporary
  body file outside the repository; foreign commits likewise use a temporary
  message file. No invented native tool names.
- Codex roles without `bash` get `sandbox_mode = "read-only"`; writable roles use
  the harness's normal policy. This is a sandbox, not a mapped OMP tool allowlist.
- DSH scouts remain read-only by instructions, **not** tool restrictions. Extra
  `subagent` rows with `toolFilter` are the documented upgrade path if needed.
  Frozen DSH tool inputs prevent rewriting child prompts.
- Claude maps advisor/task/bard/smol/commit to opus/sonnet/sonnet/haiku/haiku;
  Antigravity maps them to pro/pro/flash/flash/flash. Codex and DSH inherit the
  session model; OMP retains its configured `@role` references.

## Caveman and Ponytail

Both are always on, with no toggles or saved state. Caveman shapes replies to
Toph; Ponytail shapes engineering and also reaches subagents. Each harness uses
the native file whose reach matches that intent:

| Harness | Caveman | Ponytail | Subagents |
| --- | --- | --- | --- |
| OMP | `.omp/agent/APPEND_SYSTEM.md` | Appended to `RULES.md` | `task` children get `RULES.md`, not `AGENTS.md` or `APPEND_SYSTEM.md` |
| Claude Code | `.claude/output-styles/caveman.md`, selected by `outputStyle` | Appended to `CLAUDE.md` | Subagents read `CLAUDE.md` but not output styles; `Plan` skips `CLAUDE.md`, so a `SubagentStart` hook feeds it Ponytail |
| Codex | `.codex/AGENTS.md` | `.codex/AGENTS.md` | `spawn_agent` children inherit `AGENTS.md`, Caveman included |
| Antigravity | `.gemini/GEMINI.md` | `.gemini/GEMINI.md` | Custom agents load user rules, Caveman included |
| DSH | `.dsh/AGENTS.md` | `.dsh/AGENTS.md` | Subagent sessions load `AGENTS.md`, Caveman included |

Codex, Antigravity, and DSH have no main-conversation-only instruction file, so
their subagents also see Caveman.

## Macros and planning

| Harness | Macros | Plan entry/submission |
| --- | --- | --- |
| OMP | Generated `.omp/agent/macros/*.md`; `/macro [id or name]` fills editor; empty args open picker | `/decomplect` enters native plan mode interactively; `/plan <text>` for plan macros; native proposal flow |
| Claude Code | `.claude/skills/workflow/` mod; `/macro [id or name]` fills editable prompt; empty args open picker | Decomplect calls `EnterPlanMode` if needed; macro drafts retain `/plan `; submit through `ExitPlanMode` |
| Codex | `$macro-<id>` skills, not editable composer insertion | Enter `/plan` first, then invoke decomplect/plan-macro skill; present plan and wait for approval |
| Antigravity | `/macro-<id>` skills | Switch to plan mode with Shift+Tab first; present plan and wait for approval |
| DSH | Web client `/macro <id or name>` inserts editable draft; slash suggestions expose macros | `/plan [message]`; drafts retain `/plan `; submit through `exit_plan_mode` |

Macro IDs: `plan`, `phased-plan`, `plan-phase`, `ui-screens`, `pr-brent`.
Codex/Antigravity replace a leading `/plan ` with an explicit plan-mode gate and
use `pr-brent`'s `skill` instruction instead of its `/pr ` draft. OMP, Claude, and
DSH retain raw command prefixes for submission after editing. DSH macros live in
the plugin's client face, **not a host command**: a host `macro` command would
swallow client insertion. Home Manager activation upserts the `toph-workflow`
insert row into `.dsh/profiles/web/cordis.patch.yml`, the layer Settings writes,
so Settings overrides for the plugin keep working.

Claude mod maintenance: `ui.ask` permits four options; the macro picker uses
three entries plus “More macros…” while another page is needed.

## Verification without applying configurations

Run from the repository root in Fish. New/moved files must be Git-tracked before
flake evaluation sees them; stage only intended changes. These commands parse
and render without applying a system configuration:

```fish
for f in (git diff --cached --name-only --diff-filter=AM -- '*.nix')
    nix-instantiate --parse "$f" >/dev/null; or echo FAIL "$f"
end
for host in rune zebes
    nix eval --json ".#nixosConfigurations.$host.config.home-manager.users.toph.home.file" --apply 'fs: builtins.listToAttrs (builtins.filter (x: x.value != null) (map (n: { name = n; value = fs.${n}.text or null; }) (builtins.attrNames fs)))' > "/tmp/rendered-$host.json"
end
```

Inspect renders for unresolved `{{`, 13 native agents each in OMP/Claude/Codex/
Antigravity, Claude `name` frontmatter, valid Antigravity tools, five workflows,
and five macros in each native representation. Compare OMP bodies byte-for-byte
against the original Git revision and frontmatter semantically with `yq`
(`nix shell nixpkgs#yq-go`), allowing only the differences above.

For Claude, extract rendered mod files to `/tmp/cw/` and commands/agents to
`/tmp/ch/.claude/`, then:

```fish
claude plugin validate /tmp/cw
claude plugin validate /tmp/ch/.claude
# After adding a throwaway native mod-test-kit test under /tmp/cw/hooks:
claude plugin test /tmp/cw
```

Native scratch tests should cover macro fill and the picker. Exercise DSH client
draft insertion in a real browser; Node-only tests cannot prove editable browser
behavior. Keep test scripts and extracted files outside the repository and
remove them afterward.

### Manual checks after Toph switches

- **OMP:** replies are terse; a `task` subagent's prompt includes Ponytail;
  `/macro plan` fills the editor with `/plan check the code…`;
  `/review:adversarial` launches six agents; `/decomplect` enters plan mode.
- **Claude:** `/output-style` shows Caveman active; `/plugin` lists
  `workflow@skills-dir`; `/macro plan` leaves editable text;
  `/review:adversarial` dispatches six named agents returning final fenced JSON.
- **Codex:** `$review` lists `$review-adversarial`; replies are terse.
- **Antigravity:** `/review-adversarial` invokes six custom agents; replies are
  terse. Plan skills require Shift+Tab plan mode.
- **DSH:** browser `/macro plan` creates an editable draft, not a model turn;
  replies are terse; Settings → Plugins lists `toph-workflow`.
