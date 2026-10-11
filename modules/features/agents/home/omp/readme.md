# Oh My Pi (OMP)

Toph's [Oh My Pi](https://github.com/can1357/oh-my-pi) configuration. Managed via Nix to provide reproducible settings, model catalog, extensions, workflow commands, scout agents, prompt macros, and Context Mode.

---

## Directory Structure

```text
modules/features/agents/home/omp/
├── default.nix       # Settings, model providers, home.file wiring, activation
├── catalog.nix       # Renders ../../catalog into ~/.omp/agent (prompts, agents, commands, macros)
└── extensions/       # Hand-written TypeScript extensions → ~/.omp/agent/extensions/
```

- **`default.nix`**: Generates `~/.omp/agent/config.yml`, `models.yml`, and `ssh.json` (Nix-managed hosts). Handles activation to register Context Mode in `mcp.json` and `plugins/package.json`.
- **`catalog.nix`**: Writes `AGENTS.md`, `RULES.md` (rules plus Ponytail, which `task` subagents also receive), `APPEND_SYSTEM.md` (Caveman, main session only), `commands/`, `agents/`, and `macros/` under `~/.omp/agent/`. Prompt text lives in `../../catalog/`; edit it there.
- **`extensions/`**: Linked file-by-file into `~/.omp/agent/extensions/`.

---

## Extensions

Custom TypeScript extensions running inside OMP:

| Extension | What it does |
| --- | --- |
| **`macros.ts`** | Adds `/macro [name]` and `Ctrl+M` keybind to open an interactive picker for prompt templates in `~/.omp/agent/macros/`. Strips frontmatter before pasting into the composer. |
| **`luna-priority.ts`** | Injects `service_tier: "priority"` into requests targeting `openai-codex/gpt-5.6-luna`. |
| **`decomplect.ts`** | Routes `/decomplect` into native plan mode before the command runs. |

---

## Macros (`~/.omp/agent/macros/`, source `../../catalog/macros/`)

Reusable prompts inserted via `Ctrl+M` or `/macro <name>`:

- **`plan.md`**: Top-level system architecture and task decomposition.
- **`phased-plan.md`**: Comprehensive phased implementation plan with checkpoints.
- **`plan-phase.md`**: Detailed execution breakdown for a single phase from an existing plan.
- **`ui-screens.md`**: Walk through UI changes in browser and capture screenshots to `screens/`.
- **`pr-brent.md`**: Create PR from committed changes and request review from `brent-pysnk-ai`.

---

## Commands & Subagents

### Slash Commands

| Command | Description |
| --- | --- |
| **`/review:adversarial [target]`** | Runs 6 parallel read-only scout agents over a target (PR, commit, diff, or paths). Synthesizes findings, asks what to fix via an interactive prompt, then applies chosen fixes. |
| **`/cleanup [commit] [focus]`** | Runs 4 scout agents over working tree or diff to polish code. Applies safe fixes automatically and routes uncertain or high-risk findings to a review list. |
| **`/decomplect [repo-or-paths] [focus]`** | Enters native plan mode, audits a whole repo or selected subsystems with parallel `decomplect-scout` agents, discusses architectural/product choices, then opens one integrated plan to untangle, consolidate, and delete in Plan Review. |
| **`/commit [guidance]`** | Delegates to the `committer` agent to inspect the staged diff and create a clean conventional commit. |
| **`/pr [target] [guidance]`** | Resolves the target repo, then delegates to the `pr` agent to open a signed GitHub PR from committed changes, creating a `pr/*` branch if currently on `main` or `dev/*`. |

### Subagents (`~/.omp/agent/agents/`, source `../../catalog/agents/`)

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
- **Decomplect Scout**:
  - `decomplect-scout`: Subsystem audit for untangling, consolidation, and deletion.
- **Git Agents**:
  - `committer`: Inspects staged git diff and drafts conventional commits.
  - `pr`: Opens a GitHub PR from the exact merge-base diff via the `github` tool.

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
- **Local Models**: Preconfigured provider `zebes` connects to llama-server on host Zebes (Qwen3.8 27B plus Qwen3.5 9B models, thinking enabled).

---

## Context Mode

Context Mode runs commands and file processing in a sandboxed subprocess and maintains an FTS5 search index over local documents and logs.

- Registered as both an MCP server (`mcp.json`) and an OMP plugin (`plugins/package.json`).
- Mutable index database stored in `~/.omp/context-mode/`.
