# Oh My Pi (OMP)

Toph's independent [Oh My Pi](https://github.com/can1357/oh-my-pi) configuration. Nix manages settings, model providers, extensions, workflow commands, scout agents, prompt macros, and Context Mode. Edit the native workflow directly in `agent/`; it is not generated or shared with other harnesses.

---

## Directory Structure

```text
modules/features/agents/home/omp/
├── default.nix               # Settings, model providers, home.file wiring, activation
└── agent/                    # Recursively linked into ~/.omp/agent/
    ├── AGENTS.md             # Main-session Soul; not loaded by task subagents
    ├── RULES.md              # Standing rules plus Ponytail; inherited by task subagents
    ├── APPEND_SYSTEM.md      # Always-on Caveman; main session only
    ├── agents/               # Specialized native subagents
    ├── commands/             # Native slash-command prompts
    ├── macros/               # Editable prompt templates
    └── extensions/           # Macro picker, priority requests, native plan-mode routing
```

- **`default.nix`**: Generates `models.yml` and the declared settings and SSH hosts. Activation resets `~/.omp/agent/config.yml`, merges Nix-managed hosts into mutable `ssh.json`, and registers Context Mode in mutable `mcp.json` and `plugins/package.json`, preserving unrelated registry entries.
- **`agent/`**: Home Manager links the native files recursively, leaving room for runtime state in `~/.omp/agent/`. Change prompts, agent definitions, commands, macros, and extensions here, then activate Home Manager to deploy them.
- **Prompt reach**: `AGENTS.md` shapes the main session. `RULES.md` includes always-on Ponytail and is inherited by native `task` children. `APPEND_SYSTEM.md` supplies always-on Caveman to the main session only. These OMP-owned files need no toggle extensions, task-input rewriting, or persistence state.

---

## Extensions

Custom TypeScript extensions running inside OMP:

| Extension | What it does |
| --- | --- |
| **`macros.ts`** | Adds `/macro [name]` and `Ctrl+M` keybind to open an interactive picker for prompt templates in `~/.omp/agent/macros/`. Strips frontmatter before pasting into the composer. |
| **`luna-priority.ts`** | Injects `service_tier: "priority"` into requests targeting `openai-codex/gpt-5.6-luna`. |
| **`decomplect.ts`** | Routes `/decomplect` into native plan mode before the command runs. |

---

## Macros (`agent/macros/`)

Reusable prompts inserted via `Ctrl+M` or `/macro <name>`:

- **`plan.md`**: Vet claims against code and discuss a self-contained implementation plan.
- **`phased-plan.md`**: Outline phases with goals and constraints; leave detailed implementation to separate phase plans.
- **`plan-phase.md`**: Flesh out one phase of an existing plan for execution in a fresh session.
- **`ui-screens.md`**: Walk through UI changes in browser and capture screenshots to `screens/`.
- **`pr-brent.md`**: Create a PR from committed changes and request review from `brent-pysnk-ai`.

---

## Commands & Subagents

### Slash Commands

| Command | Description |
| --- | --- |
| **`/review:adversarial [target]`** | Runs 6 parallel read-only scout agents over a target (PR, commit, diff, or paths). Synthesizes findings, asks what to fix via an interactive prompt, then applies chosen fixes. |
| **`/cleanup [commit] [focus]`** | Runs 4 scout agents over working tree or diff to polish code. Applies safe fixes automatically and routes uncertain or high-risk findings to a review list. |
| **`/decomplect [repo-or-paths] [focus]`** | Enters native plan mode, audits a whole repo or selected subsystems with parallel `decomplect-scout` agents, discusses architectural/product choices, then opens one integrated plan to untangle, consolidate, and delete in Plan Review. |
| **`/commit [guidance]`** | Delegates to the `committer` agent to inspect the staged diff and create a clean conventional commit. |
| **`/pr [target] [guidance]`** | Resolves the target repo, then delegates to the `pr` agent to open a GitHub PR from committed changes, creating a `pr/*` branch if currently on `main` or `dev/*`. |

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
- **Decomplect Scout**:
  - `decomplect-scout`: Subsystem audit for untangling, consolidation, and deletion.
- **Git Agents**:
  - `committer`: Inspects staged git diff and drafts conventional commits.
  - `pr`: Opens a GitHub PR from the exact merge-base diff via the `github` tool.

---

## Model Roles & Keybinds

OMP uses abstract model roles instead of hardcoded model IDs. Subagents and workflows reference roles (e.g., `model: "@advisor"`), allowing models to be swapped globally in `default.nix`. Native discovery remains isolated from other harnesses through `disabledProviders`, and the built-in `scout` uses `@bard`.

| Role | Default Model |
| --- | --- |
| `default` | `google-antigravity/gemini-3.8-flash:high` |
| `bard` | `google-antigravity/gemini-3.8-flash:high` |
| `commit` | `google-antigravity/gemini-3.8-flash:low` |
| `plan` | `anthropic/claude-opus-5-5:high` |
| `task` | `openai-codex/gpt-6.1-sol:high` |
| `smol` | `openai-codex/gpt-6-luna:xhigh` |
| `advisor` | `anthropic/claude-opus-5-5:medium` |
| `claude` | `anthropic/claude-opus-5-5:high` |
| `codex` | `openai-codex/gpt-6.1-sol:high` |

- **`Ctrl+P`**: Cycles active model: `default → bard → claude → codex`.
- **Local Models**: The `zebes` provider retains its private-IP llama-server router endpoint, unauthenticated local access, model list from `../_zebes-models.nix`, and Qwen thinking compatibility.
- **DeepSeek**: `models.yml` includes the DeepSeek provider when `secrets.service.models.DEEPSEEK_API_KEY` is configured.
- **Gemini**: `models.yml` includes the Google provider when `secrets.service.models.GEMINI_API_KEY` is configured.

---

## Context Mode

Context Mode runs commands and file processing in a sandboxed subprocess and maintains an FTS5 search index over local documents and logs.

- Registered as both an MCP server (`mcp.json`) and an OMP plugin (`plugins/package.json`).
- Mutable index database stored in `~/.omp/context-mode/`.

---

## REA (Reverse Engineer Anything)

REA provides 170 MCP tools for reverse engineering across binaries, managed code, JavaScript/Electron apps, APKs, EVM bytecode, and network captures.

- Packaged in `mix.nix` (`pkgs.rea`) with pre-wrapped analysis engines: Ghidra 12.1.x, OpenJDK 21, Python pwntools, WABT, JADX, Android platform tools (adb), Wireshark CLI (tshark), Sigrok CLI, Binwalk, Unblob, Mitmproxy, and GDB.
- Registered as an MCP server (`mcp.json`) invoking `${lib.getExe pkgs.rea} mcp`.
- Workflow instructions linked to `~/.agents/skills/reverse-engineer-anything` from `pkgs.rea.passthru.skill`.
