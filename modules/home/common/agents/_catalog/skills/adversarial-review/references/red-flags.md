# Red flags — language-specific catalogue

The original adversarial-review's red-flag catalogue, expanded with idioms from sworm-review (Svelte 5, Tauri/Rust boundary) and entries for Nix, Go, and SQL. Apply these inside the relevant scope (mostly Scope 3 — Idiom Compliance, with crossover to Scope 1 — Architecture Fit and Scope 5 — Efficiency).

## Universal adversarial lens

Apply across every language and every scope:

- Every unhandled Promise / future / async result will reject at 3am.
- Every `None` / `null` / `undefined` / `NA` / `nil` will appear where you don't expect it.
- Every API response will be malformed.
- Every user input is malicious (XSS, injection, type coercion attacks).
- Every "temporary" solution is permanent.
- Every `any` / `unknown` / `interface{}` / `dyn Trait` widens the type and earns scrutiny.
- Every missing `try / except` / `Result::Err` handling is a silent failure.
- Every fire-and-forget promise / goroutine / task is a silent failure.
- Every missing `await` / `.await` is a race condition or a leaked future.

## Slop detector (cross-language)

These are findings regardless of language:

- **Obvious comments**: `// increment counter` above `counter++`, `# loop through items` above a `for`. Delete.
- **Lazy naming**: `data`, `temp`, `result`, `handle`, `process`, `df`, `df2`, `x`, `val`, `obj`, `info` — words that communicate nothing.
- **Copy-paste artifacts**: similar blocks that scream "I didn't think about abstraction".
- **Cargo cult code**: patterns used without understanding why (e.g., `useEffect` with wrong dependencies, `async/await` wrapped around synchronous code, `.apply()` in pandas where vectorization works, `clone()` to dodge a borrow that has a non-clone solution).
- **Premature abstraction AND missing abstraction**: both are failures of judgment.
- **Dead code**: commented-out blocks, unreachable branches, unused imports / variables.
- **Overuse of comments**: well-named functions and variables should explain intent without comments.

## JavaScript / TypeScript

- `==` instead of `===`.
- `any` type abuse — every `any` is a finding unless commented with WHY.
- `as` casts of unknown values without runtime validation.
- Missing null checks before property access.
- `var` in modern codebases.
- Missing `await` on async calls.
- Unhandled promise rejections.
- Uncontrolled re-renders in React (missing memoization, unstable references).
- `useEffect` dependency array lies, stale closures, missing cleanup.
- `key` prop abuse (using index as key for dynamic lists).
- Inline object / function props in memoized children.
- Wrapping a synchronous call in `async` for no reason.
- `.then().then().then()` chains that should be `await`.

## Svelte 5

- `export let` instead of `$props()`.
- `$state` storing a value that should be `$derived` / `$derived.by`.
- `$effect` for derived state, prop syncing, or general control flow (treat as React `useEffect` cargo culting).
- Slots instead of `{#snippet}` / `{@render}` in new code.
- `use:` actions where `{@attach}` is now preferred.
- Shared state in classic stores when a `.svelte.ts` rune module would fit.
- Reactive statements (`$:`) in Svelte 5 code (Svelte 4 syntax in new code).

## Tauri / Native boundary (desktop apps with Rust backend)

- Browser API used where a Tauri / Rust path exists (clipboard, filesystem, process, OS integration).
- Direct `invoke()` from feature code instead of going through a typed bridge in `src/lib/`.
- Web-server assumptions in a desktop SPA.
- `tauri-plugin-shell` (almost always wrong; specific commands belong in Rust).
- Frontend code reading files outside the Tauri-allowlisted paths.

## Rust

- `unwrap()` without justification — Blocking in library code, Required in binary code unless commented.
- `expect("...")` with a message that doesn't say *why* it can't fail.
- `clone()` to dodge a borrow that has a non-clone solution.
- `match` on `Option` / `Result` where `?`, `.ok_or`, `.unwrap_or`, `.map_err` would read cleaner.
- `String` where `&str` works; `Vec<T>` where `&[T]` works.
- `Box<dyn Trait>` for one caller — over-abstraction.
- Lifetimes elided where they should be named for clarity in complex signatures.
- Naked `panic!` in production paths.
- Missing `#[must_use]` on builder / `Result`-returning APIs.
- `unsafe` blocks without a `// SAFETY:` comment justifying every invariant.
- Allocating in a loop where iterator chains would be lazy.

## Python

- Bare `except:` clauses swallowing all errors.
- `except Exception:` that catches but doesn't re-raise.
- Mutable default arguments (`def foo(items=[])`).
- Global state mutations.
- `import *` polluting namespace.
- Ignoring type hints in typed codebases (project has `py.typed` or strict pyright config).
- `os.path` usage in a `pathlib` codebase.
- Synchronous I/O in an async function (file reads, `requests` instead of `httpx`).
- `dict.get(key)` followed by a separate `if x in dict` check (race / re-lookup).
- Pandas `.apply()` where vectorization works.

## Nix

- `with pkgs;` in a long block — hides where each name comes from; OK for short blocks (3–5 names).
- `//` for set merging where `lib.mkMerge` priority semantics matter.
- `pkgs.<name>` where `pkgsCross.<arch>.<name>` is needed for cross-builds.
- Missing `inputs.<name>.follows` causing duplicated nixpkgs in the lockfile.
- IFD (import-from-derivation) without acknowledging the eval-time cost.
- `builtins.fetchurl` / `fetchTarball` without `sha256` pin.
- `lib.optional` (singular) vs `lib.optionals` (plural) confusion — `optional` returns `[x]` or `[]`, `optionals` returns `xs` or `[]`.
- Hardcoded `/nix/store/...` paths.
- `services.foo.enable = true` without the corresponding config.
- Mutable home-manager files outside the staging pattern (writing to `~/.claude/settings.json` directly when the project uses an `onChange` hook to copy from `settings_source`).

## Go

- Error wrapping with `%v` instead of `%w` losing the error chain.
- `if err != nil { return err }` without context — wrap with `fmt.Errorf("X: %w", err)`.
- Naked `panic` in non-init code paths.
- Goroutines launched without a corresponding cancellation / wait (leak).
- Missing `context.Context` propagation in long-running operations.
- Unbuffered channels in producer-consumer patterns where buffering is needed.
- `interface{}` / `any` abuse where a concrete type or generics would fit.
- `time.Sleep` in tests (use `testify/assert.Eventually` or similar).
- Unguarded shared state — slices / maps accessed concurrently without `sync.Mutex` or channels.

## SQL / ORM

- Raw string interpolation in queries (SQL injection risk) — Blocking.
- N+1 query patterns — loading a parent then iterating children with separate queries.
- Missing indexes on frequently queried columns (flag for review when a new query references a non-indexed column).
- Unbounded queries without `LIMIT`.
- `SELECT *` in production paths (silent breakage when schema changes).
- Missing transaction boundaries on multi-statement updates.
- Migrations that aren't reversible without justification.

## Front-end general

- Accessibility violations (missing alt text, unlabeled inputs, missing focus states, poor contrast).
- Layout shifts from unoptimized images / fonts.
- N+1 API calls inside `.map()` / loops.
- State management chaos (prop drilling 5+ levels, global state for local concerns).
- Hardcoded user-facing strings that should be i18n-ready.
- Inline styles where the project uses CSS modules / Tailwind / styled-components.
- New design tokens (raw colors, ad-hoc spacing) when the design system has tokens for them.

## Shell

- Unquoted variable expansions: `rm $foo` instead of `rm "$foo"`.
- `cd $dir && ...` without checking `cd` succeeded.
- `set -e` not set (errors silently ignored).
- `#!/bin/sh` with bashisms inside.
- Hardcoded paths that should be `$HOME` or auto-discovered.
- `find ... -exec rm` without `-delete` flag (slower; spawns rm per file).
- Backticks instead of `$(...)`.

## Fish

- Bashisms (`if [ -f x ]` instead of `test -f x` or `if test -f x`).
- `set` without `--global` / `--export` / `--local` when scope matters.
- Hardcoded `/bin/sh` shebangs in fish scripts.
- Calling subshells (`( cmd )`) when fish's `begin ... end` is the idiom.

## When a finding crosses categories

A `// TODO: handle this case` in TypeScript code is:
- A **slop** finding (doesn't actually handle the case).
- Possibly a **Quality** scope finding (comment narrating something that should be code).
- Possibly **Blocking** if the unhandled case is a real bug path.

Pick the highest-severity scope and let the dedupe step handle the rest.
