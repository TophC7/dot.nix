# Oh My Pi (OMP)

Toph's [Oh My Pi](https://github.com/can1357/oh-my-pi) configuration. Managed via Nix to provide reproducible settings, model catalog, extensions, workflow commands, scout agents, prompt macros, and Context Mode.

---

## Directory Structure

```text
modules/home/common/agents/omp/
├── default.nix               # Nix configuration: settings, model providers, activation
└── agent/                    # Symlinked to ~/.omp/agent/
    ├── AGENTS.md             # Core agent prompt ("Soul")
    ├── extensions/           # Custom OMP runtime extensions
    ├── macros/               # Reusable prompt templates (Ctrl+M / /macro)
    ├── commands/             # Slash commands (/review:adversarial, /cleanup, etc.)
    └── agents/               # Specialized subagents (scouts and committer)
```

- **`default.nix`**: Generates `~/.omp/agent/config.yml` and `models.yml`. Handles activation to register Context Mode in `mcp.json` and `plugins/package.json`.
- **`agent/`**: Installed directly as `~/.omp/agent/` via Home Manager symlinks.

---

## Extensions

Custom TypeScript extensions running inside OMP:

| Extension | What it does |
| --- | --- |
| **`antigravity.ts`** | Fixes Google Antigravity OAuth requests. Drops `requestType` to match the official client envelope and rewrites `<system-conventions>` tags to `<system_conventions>` to bypass Google's prompt-fingerprint filter. |
| **`macros.ts`** | Adds `/macro [name]` and `Ctrl+M` keybind to open an interactive picker for prompt templates in `agent/macros/`. Strips frontmatter before pasting into the composer. |
| **`luna-priority.ts`** | Injects `service_tier: "priority"` into requests targeting `openai-codex/gpt-5.6-luna`. |
| **`caveman.ts`** | Adds `/caveman [on\|off]` to enforce terse, fluff-free responses while keeping technical substance intact. State persists across sessions and branches. |
| **`ponytail.ts`** | Adds `/ponytail [on\|off]` to enforce senior pragmatic engineering heuristics (reuse existing code first, stdlib over extra deps, avoid speculative abstractions). State persists across sessions and branches. |

---

## Macros (`agent/macros/`)

Reusable prompts inserted via `Ctrl+M` or `/macro <name>`:

- **`plan.md`**: Top-level system architecture and task decomposition.
- **`phased-plan.md`**: Comprehensive phased implementation plan with checkpoints.
- **`plan-phase.md`**: Detailed execution breakdown for a single phase from an existing plan.

---

## Commands & Subagents

### Slash Commands

| Command | Description |
| --- | --- |
| **`/review:adversarial [target]`** | Runs 6 parallel read-only scout agents over a target (PR, commit, diff, or paths). Synthesizes findings, asks what to fix via an interactive prompt, then applies chosen fixes. |
| **`/cleanup [commit] [focus]`** | Runs 4 scout agents over working tree or diff to polish code. Applies safe fixes automatically and routes uncertain or high-risk findings to a review list. |
| **`/commit [guidance]`** | Delegates to the `committer` agent to inspect the staged diff and create a clean conventional commit. |
| **`/pr [guidance]`** | Opens a GitHub PR from committed changes, creating a `pr/*` branch if currently on `main` or `dev`. |

### Subagents (`agent/agents/`)

Subagents run in parallel with `blocking: true` to return findings inline:

- **Review Scouts**:
  - `review-adversarial-architecture-scout`: Boundaries, ownership, modularity.
  - `review-adversarial-reuse-scout`: Existing utility and pattern reuse.
  - `review-adversarial-idiom-scout`: Language, framework, and repo idioms.
  - `review-adversarial-quality-scout`: Dead code, logic bugs, debug remnants.
  - `review-adversarial-efficiency-scout`: Hot paths, allocations, missed concurrency.
  - `review-adversarial-comment-scout`: Stale, missing, or misleading comments.
- **Cleanup Scouts**:
  - `cleanup-reuse-scout`: Flags duplicate utility logic.
  - `cleanup-quality-scout`: Removes dead code and debug remnants.
  - `cleanup-efficiency-scout`: Streamlines loops and hot paths.
  - `cleanup-audit-scout`: Flags risky behavioral changes, races, and seam breaks for manual triage.
- **Committer**:
  - `committer`: Inspects staged git diff and drafts conventional commits.

---

## Model Roles & Keybinds

OMP uses abstract model roles instead of hardcoded model IDs. Subagents and workflows reference roles (e.g., `model: "@audit"`), allowing models to be swapped globally in `default.nix`.

| Role | Default Model |
| --- | --- |
| `default` | `google-antigravity/gemini-3.8-flash:high` |
| `bard` | `google-antigravity/gemini-3.8-flash:high` |
| `commit` | `google-antigravity/gemini-3.8-flash:low` |
| `plan` | `anthropic/claude-fable-5-1:medium` |
| `designer` | `anthropic/claude-opus-5:high` |
| `task` | `openai-codex/gpt-5.6-sol:high` |
| `smol` | `openai-codex/gpt-5.6-luna:xhigh` |
| `tiny` | `openai-codex/gpt-5.3-codex-spark` |
| `audit` | `openai-codex/gpt-6-astra:low` |

- **`Ctrl+P`**: Cycles active model: `default → bard → task → audit → plan → designer → smol`.
- **Local Models**: Preconfigured provider `zebes` connects to llama-server on host Zebes (Qwen3.5/Ornith models with thinking enabled).

---

## Context Mode

Context Mode runs commands and file processing in a sandboxed subprocess and maintains an FTS5 search index over local documents and logs.

- Registered as both an MCP server (`mcp.json`) and an OMP plugin (`plugins/package.json`).
- Mutable index database stored in `~/.omp/context-mode/`.
