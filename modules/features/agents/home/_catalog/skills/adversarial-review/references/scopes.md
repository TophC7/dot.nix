# Six-scope swarm — full prompts

Dispatch one agent per scope in a single tool-call message. Each agent's prompt should include:

1. The exact diff or file list under review.
2. The agent's scope number and scope question.
3. The "must read" list for that scope (relative to detected stack).
4. The Output Contract (single table, schema, severity sort, 5-row default cap).
5. The "go higher only for genuine independent issues" rule.

The prompts below are the per-scope cores; concatenate with the diff and shared output contract before dispatch.

---

## Scope 1 — Architecture Fit

**Question:** Does the change respect the project's existing layering and architectural boundaries?

**Lens:**
- Does new code go where the project's structure says it should — features under their feature folder, services in the services dir, UI primitives in the primitives dir, etc.? Auto-discover by inspecting the project's existing layout.
- Does the change route data through the project's typed boundaries (typed API wrappers, schema-validated handlers, command/service split) rather than bypassing them?
- Does it solve the right *kind* of problem for this codebase? Web-only assumption in a desktop app, browser API in a Tauri context, server framework idiom in a CLI — these are real architectural breaks.
- Does the change introduce a new module boundary (a new top-level dir, a new service layer) without justification?

**Must read:**
- The project's `README.md` architecture section.
- The directory tree adjacent to changed files (one level up, one level down).
- The typed-bridge / API-layer file if one exists (e.g. `src/lib/api/*`, `src-tauri/src/commands/*`, `internal/api/*`).
- Any `ARCHITECTURE.md` / `ADR/` that exists.

**Examples of real findings:**
- "New code calls upstream `library.fn()` directly when the project has a typed wrapper at `src/lib/wrappers/library.ts` that all other call sites use."
- "Adds a fetch in a Tauri desktop app for a resource that has a Rust command in `src-tauri/src/commands/`."
- "Introduces a top-level `utils/` directory in a feature-folder codebase; should live under `feature/<name>/utils/`."

---

## Scope 2 — Primitive & Pattern Reuse

**Question:** Does the change reuse existing utilities, helpers, and primitives instead of duplicating?

**Lens:**
- Does it import the project's wrapper components (e.g. `Button` from `components/ui/`) instead of the upstream library directly (e.g. `bits-ui`, `radix-ui`, `headlessui`)?
- Does it create a new dialog / modal / popover variant where an existing primitive would extend?
- Does it duplicate a flow, store, hook, helper, or component? Search for existing names and shapes before flagging "missing" — the answer is sometimes "exists already at unexpected path".
- Does it add a new util that wraps a stdlib function with no value-add?

**Must read:**
- The project's primitives / components / shared-utils directory (e.g. `src/lib/components/ui/`, `internal/util/`, `pkg/common/`).
- Existing stores / hooks / helpers in adjacent feature folders.
- The CHANGELOG or recent merge commits — sometimes a primitive was added recently and the author didn't know.

**Examples of real findings:**
- "New `ConfirmDialog` component duplicates `src/lib/components/ui/dialog/Confirm.svelte` with cosmetic differences."
- "Hand-rolls path normalization where `lib/path.normalize()` already does the same thing."
- "Adds `useDebouncedValue` when `useDebounce` (different name, same behavior) exists in `src/lib/hooks/`."

---

## Scope 3 — Idiom Compliance

**Question:** Is the code idiomatic for its language / framework?

**Lens:**

Auto-detect from file extensions in the diff. Apply only the relevant blocks; don't flag Python idioms in a Rust diff.

### React (`.tsx`, `.jsx`)
- `useEffect` with wrong / lying dep arrays.
- `useEffect` to derive state (use `useMemo` / a derived value).
- Inline object / function props causing unnecessary re-renders in memoized children.
- `key={index}` on dynamic lists.
- Missing `useCallback` / `useMemo` where stable references matter.
- Stale closures over state inside effects.
- Missing cleanup in effects with subscriptions / timers.

### Svelte 5 (`.svelte`, `.svelte.ts`)
- `export let` instead of `$props()`.
- `$state` storing a derived value that should be `$derived` / `$derived.by`.
- `$effect` to mirror state, sync props, or imitate `useEffect`.
- Slots instead of `{#snippet}` / `{@render}`.
- `use:` actions instead of `{@attach}`.
- Shared state in classic stores when a `.svelte.ts` rune module would do.
- React cargo culting in general.

### Rust (`.rs`)
- `unwrap()` without justification (panic-on-`None`/`Err` is a Blocking finding in library code).
- `clone()` to dodge a borrow checker fight that has a non-clone solution.
- `match` on `Option`/`Result` where `?` / `.ok_or` / `.unwrap_or` would read cleaner.
- `String` where `&str` would suffice; `Vec<T>` where `&[T]` would suffice.
- `Box<dyn Trait>` introduced for one caller (over-abstraction).
- Lifetimes elided where they should be explicit (named lifetimes for clarity).
- Naked `panic!` in production paths.
- Missing `#[must_use]` on builder / `Result`-returning APIs.

### Python (`.py`)
- Bare `except:` clauses or `except Exception` that catches and doesn't re-raise.
- Mutable default args (`def foo(items=[])`).
- Global state mutations.
- `import *` polluting namespace.
- Type hints missing in a typed codebase (check for existing `py.typed` / pyright config).
- `os.path` where `pathlib.Path` is the project convention.
- Synchronous I/O in an async function.

### TypeScript (`.ts`, `.tsx`)
- `any` abuse — every `any` is a finding unless commented with WHY.
- `==` instead of `===`.
- Missing null checks before property access.
- `var` in modern code.
- `as` casts of unknown values without runtime validation.
- Missing `await` on async calls.
- Stale closures / unstable references in React contexts.

### Nix (`.nix`)
- `with pkgs;` in a long block that hides where each name comes from.
- `//` for set merging where `lib.mkMerge` semantics matter (priorities).
- `pkgs.<name>` where `pkgsCross.<arch>.<name>` is needed.
- Missing `inputs.<name>.follows` causing duplicated nixpkgs.
- IFD (import-from-derivation) without acknowledging the cost.
- `builtins.fetchurl` without `sha256` pin.
- `lib.optional` vs `lib.optionals` confusion.

### Go (`.go`)
- Error wrapping with `%v` instead of `%w` losing the chain.
- Naked `panic` in non-init code paths.
- Missing context propagation in long-running operations.
- Goroutines launched without a corresponding cancellation / wait.
- Unbuffered channels in producer-consumer patterns where buffering is needed.
- `interface{}` / `any` abuse.

### SQL (any embedded SQL)
- String interpolation in queries (injection risk) — Blocking unless input is statically typed and known-safe.
- `SELECT *` in production paths.
- Unbounded queries (`SELECT ... FROM huge_table` without `LIMIT`).
- N+1 query loops.
- Missing transaction boundaries on multi-statement updates.

### Front-end general
- Accessibility: missing alt text, unlabeled inputs, missing focus states, poor contrast.
- Layout shifts from unoptimized images / fonts.
- Hardcoded strings that should be i18n-ready.
- Inline styles where the project uses CSS modules / Tailwind / styled.

**Must read:**
- The framework / runtime config files (`package.json`, `Cargo.toml`, `pyproject.toml`, etc.) to know exact versions and detect framework-version-specific idioms.
- The project's existing components / modules in the same area for idiom comparison.

---

## Scope 4 — Quality

**Question:** Does the change introduce hacky patterns, redundant state, parameter sprawl, or other quality issues?

**Lens:**
- **Redundant state**: state that duplicates existing state, cached values that could be derived, observers / effects that could be direct calls.
- **Parameter sprawl**: adding new parameters to a function instead of generalizing or restructuring existing ones.
- **Copy-paste with slight variation**: near-duplicate code blocks that should be unified with a shared abstraction.
- **Leaky abstractions**: exposing internal details that should be encapsulated, or breaking existing abstraction boundaries.
- **Stringly-typed code**: using raw strings where constants, enums (string unions), or branded types already exist in the codebase.
- **Unnecessary JSX / template nesting**: wrapper elements that add no layout value — check if inner-component props already provide the needed behavior.
- **Unnecessary comments**: comments explaining WHAT the code does (well-named identifiers already do that), narrating the change, or referencing the task/caller — delete; keep only non-obvious WHY.
- **Dead code**: commented-out blocks, unreachable branches, unused imports / variables.

**Must read:**
- Adjacent files in the same module for comparison.
- The project's comment-style guide if present.

---

## Scope 5 — Efficiency

**Question:** Does the change introduce unnecessary work, missed concurrency, or hot-path bloat?

**Lens:**
- **Unnecessary work**: redundant computations, repeated file reads, duplicate network / API calls, N+1 patterns.
- **Missed concurrency**: independent operations run sequentially when they could run in parallel (`Promise.all`, `tokio::join!`, etc.).
- **Hot-path bloat**: new blocking work added to startup or per-request / per-render hot paths.
- **Recurring no-op updates**: state / store updates inside polling loops, intervals, or event handlers that fire unconditionally — add a change-detection guard so downstream consumers aren't notified when nothing changed. Also: if a wrapper function takes an updater / reducer callback, verify it honors same-reference returns (or whatever the "no change" signal is) — otherwise callers' early-return no-ops are silently defeated.
- **Unnecessary existence checks**: pre-checking file / resource existence before operating (TOCTOU anti-pattern) — operate directly and handle the error.
- **Memory**: unbounded data structures, missing cleanup, event listener leaks.
- **Overly broad operations**: reading entire files when only a portion is needed, loading all items when filtering for one.

**Must read:**
- Hot-path entry points in the project (startup, request handlers, render functions).
- Any existing performance docs or benchmarks.

---

## Scope 6 — Comment Style

**Question:** Do comments follow project conventions and add real value?

**Lens:**
- Comments explain non-obvious WHY (hidden constraints, subtle invariants, workarounds for specific bugs, rationale that wouldn't survive a future refactor).
- Comments do NOT explain WHAT (well-named identifiers do that).
- Comments do NOT narrate the change ("added for the X flow", "used by Y").
- Comments do NOT reference the PR / task / caller — those rot when the surrounding code changes.
- Misleading, stale, or AI-narrated comments are real quality issues, not nits.
- `// TODO` / `# FIXME` without a tracking issue ID and tight rationale is a smell.

**Must read:**
- The project's comment-style guide (if any). Common locations:
  - `.claude/comment-style/SKILL.md`
  - `comment-style/SKILL.md`
  - `docs/style/comments.md`
  - A `## Comments` section in `CONTRIBUTING.md`.

If no guide, apply the default rule above.

**Examples of real findings:**
- "`// increment counter` above `counter++` — slop comment; delete."
- "`// added for the dashboard flow` references caller; will rot when the dashboard refactors."
- "`/* TODO: handle null */` without an issue ID and the function below proceeds without handling null — Blocking, not a TODO."

---

## Dispatch checklist

Before sending the swarm:

- [ ] Hard Gate reads completed (CLAUDE.md, AGENTS.md, comment-style, manifest, full diff).
- [ ] 2–3 sentence change summary drafted (proves Hard Gate).
- [ ] Stack auto-detected; per-scope must-reads adjusted.
- [ ] All six prompts assembled with diff + scope question + must-read + output contract + 5-row cap.
- [ ] Single tool-call message dispatches all six agents in parallel.

After all six return:

- [ ] Merge tables; dedupe by `path:line`.
- [ ] Re-sort by severity, then location.
- [ ] Renumber `#` from 1.
- [ ] If total > 20, split Blocking + Required into the table and Suggestions into an appendix.
- [ ] Compose the final report structure.
