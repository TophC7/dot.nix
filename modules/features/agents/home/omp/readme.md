# Oh My Pi (OMP)

Toph's independent [Oh My Pi](https://github.com/can1357/oh-my-pi) configuration. Nix manages settings, model providers, extensions, workflow commands, scout agents, and prompt macros. Edit the native workflow directly in `agent/`; it is not generated or shared with other harnesses.

---

## Directory Structure

```text
modules/features/agents/home/omp/
├── default.nix               # Settings, model providers, home.file wiring, activation
└── agent/                    # Recursively linked into ~/.omp/agent/
    ├── AGENTS.md             # Main-session Soul; not loaded by task subagents
    ├── RULES.md              # Standing rules plus Ponytail; inherited by task subagents
    ├── PERSONALITY.md        # BLUF communication style; main session only
    ├── agents/               # Specialized native subagents
    ├── commands/             # Native slash-command prompts
    ├── macros/               # Editable prompt templates
    └── extensions/           # Macro picker, priority requests, plan-mode routing, findings triage, docs search
```

- **`default.nix`**: Generates `models.yml` and the declared settings and SSH hosts. Activation resets `~/.omp/agent/config.yml`, merges Nix-managed hosts into mutable `ssh.json`, and registers REA in mutable `mcp.json`, preserving unrelated registry entries.
- **`agent/`**: Home Manager links the native files recursively, leaving room for runtime state in `~/.omp/agent/`. Change prompts, agent definitions, commands, macros, and extensions here, then activate Home Manager to deploy them.
- **Prompt reach**: `AGENTS.md` (Soul) shapes how the main session works with Toph and his ideas. `PERSONALITY.md` owns prose style for the main session; it fills OMP's personality slot because `personality` is non-`none`. `RULES.md` holds tooling and code rules, including Ponytail, that every agent including `task` children must follow. Subagents never receive Soul or Personality; the main agent conveys intent when spawning them.

---

## Extensions

Custom TypeScript extensions running inside OMP:

| Extension | What it does |
| --- | --- |
| **`macros.ts`** | Adds `/macro [id]` and `Ctrl+M` for prompt templates in `~/.omp/agent/macros/`. Root files and one level of folders load; ids are path stems (`ui-screens`, `pr/merge`). `Ctrl+M`/bare `/macro` open an accordion picker on OMP's `TreeView` (folders fold with Enter/←→). Strips frontmatter before pasting into the composer. |
| **`luna-priority.ts`** | Injects `service_tier: "priority"` into requests targeting `openai-codex/gpt-5.6-luna`. |
| **`decomplect.ts`** | Routes `/decomplect` into native plan mode before the command runs. |
| **`findings.ts`** | Registers `triage_findings`, the stateless step shared by `/cleanup` and `/review:adversarial`: folds skeptic duplicates, routes findings by verdict, gates cleanup auto-fixes, and writes the shared report to `local://findings.md`. |
| **`docs.ts`** | Registers `docs`: ranked full-text search (SQLite FTS5, BM25, stemming) over documentation. Takes a URL, local file/dir, or Nix store path and indexes it on first use into heading sections split into paragraph-aligned chunks of at most 2000 chars. Results show the heading path, a `file:start-end` range to `read`, and the page `URL#anchor` for web sources. All query terms must match (falling back to any term); dotted identifiers match as phrases and a trailing `*` matches prefixes. The index lives in `~/.omp/docs/`. URLs are re-fetched after 24h and local paths when their files change; store paths never need refreshing. Failed URL re-fetches, including explicit refreshes, search the existing index with a warning and its indexing date; cancellation still propagates. Directory walks prune hidden entries and `node_modules`, stop above 5000 doc files, and read files in batches of 32 before atomically replacing the index. Any source unused for 30 days (not searched by name and in no result) is dropped, along with its saved page, and paths that no longer exist are dropped at once. It only fetches plain HTTP and only the given page, following HTTP and meta-refresh redirects (including quoted targets). |

---

## Macros (`agent/macros/`)

Reusable prompts inserted via `Ctrl+M` or `/macro <id>`, grouped one folder deep:

- **`ui-screens`**: Generic CDP macro to exercise UI changes in browser and capture screenshots to `screens/`.
- **`plan/`**
  - **`plan`**: Vet claims against code and discuss a self-contained implementation plan.
  - **`findings`**: Turn `local://findings.md` from `/cleanup` or `/review:adversarial` into a root-cause-grouped implementation plan.
  - **`phased`**: Outline phases with goals and constraints; leave detailed implementation to separate phase plans.
  - **`phase`**: Flesh out one phase of an existing plan for execution in a fresh session.
- **`pr/`**
  - **`brent`**: Create a PR from committed changes and request review from `brent-pysnk-ai`.
  - **`review`**: Post a PR review comment detailing cleanup changes and inline findings without prescribing fixes.
  - **`merge`**: Push fixes, approve the PR with a summary of resolved findings and cleanup, and merge.
  - **`ui`**: Capture UI screenshots via CDP and attach them directly to the PR summary using `gh pr edit/create --attach`.

---

## Commands & Subagents

### Slash Commands

| Command | Description |
| --- | --- |
| **`/review:adversarial [target]`** | Read-only diagnostic review: runs 6 blind scope scouts, challenges candidates with `workflow-skeptic` and `review-omission-scout`, and writes actionable findings to `local://findings.md` without interviewing or editing. |
| **`/cleanup [target] [focus]`** | Runs 4 blind cleanup scouts, challenges candidates with `workflow-skeptic`, applies vetted mechanical fixes via `cleanup-fixer`, and reports the rest in the shared `local://findings.md` format. |
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
- **Challenge & Fixer Agents**:
  - `workflow-skeptic`: Adversarial verifier that attempts to refute candidate findings against actual code and vets `mechanical` vs `judgment` edits.
  - `review-omission-scout`: Completeness critic that hunts for unread hunks, untraced callers, and unwalked failure paths.
  - `cleanup-fixer`: Single in-lane writer for `/cleanup` that applies vetted mechanical edits, runs repo checks, and re-stages in `staged` mode.
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

## REA (Reverse Engineer Anything)

REA provides 170 MCP tools for reverse engineering across binaries, managed code, JavaScript/Electron apps, APKs, EVM bytecode, and network captures.

- Packaged in `mix.nix` (`pkgs.rea`) with pre-wrapped analysis engines: Ghidra 12.1.x, OpenJDK 21, Python pwntools, WABT, JADX, Android platform tools (adb), Wireshark CLI (tshark), Sigrok CLI, Binwalk, Unblob, Mitmproxy, and GDB.
- Registered as an MCP server (`mcp.json`) invoking `${lib.getExe pkgs.rea} mcp`.
- Workflow instructions linked to `~/.agents/skills/reverse-engineer-anything` from `pkgs.rea.passthru.skill`.
