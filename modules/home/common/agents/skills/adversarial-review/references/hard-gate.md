# Hard Gate — what to read by stack

Auto-detect the stack from file extensions in the diff. Apply the relevant must-read list before any scope agent runs.

## Always read first

Regardless of stack:

1. `CLAUDE.md` at repo root (project-level instructions).
2. `AGENTS.md` at repo root (cross-agent conventions).
3. `README.md` first 100 lines (architecture overview).
4. The diff in full (every changed file body, not just the headers).
5. Any comment-style guide — usually `.claude/comment-style/SKILL.md` or `comment-style/SKILL.md` in this user's repos.

## Per-stack manifests and follow-ons

Detect the stack from extensions present in the diff. Read everything in the matching block.

### Node / Bun / Deno (JS, TS)

`.js`, `.ts`, `.jsx`, `.tsx`, `.cjs`, `.mjs`, `.cts`, `.mts`

- `package.json` — dependencies, scripts, package manager (`packageManager` field).
- `tsconfig.json` — strictness flags (`strict`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`).
- `.eslintrc*` / `eslint.config.*` — what's already enforced (don't flag what eslint already catches).
- `vite.config.*` / `next.config.*` / `vitest.config.*` — framework signals.
- Lockfile presence (which package manager is canonical).

### Svelte / SvelteKit

`.svelte`, `.svelte.ts`, `.svelte.js`

- Everything from Node above.
- `svelte.config.js` — Svelte version, kit options.
- Look for `runes: true` indicators or rune syntax (`$state`, `$props`) to confirm Svelte 5.

### Rust

`.rs`, `Cargo.*`

- `Cargo.toml` (workspace + crate) — dependencies, edition, MSRV.
- `Cargo.lock` exists / doesn't (lib vs bin convention).
- `rust-toolchain.toml` — pinned toolchain.
- `clippy.toml`, `.clippy.toml` — what's already enforced.
- `rustfmt.toml`.

### Python

`.py`, `.pyi`

- `pyproject.toml` (preferred) or `setup.py` / `setup.cfg` / `requirements.txt`.
- `mypy.ini` / `pyrightconfig.json` — type-checking strictness.
- `.ruff.toml` / `ruff.toml` — what's already enforced.
- `tox.ini` / `pytest.ini`.
- `py.typed` marker (signals a typed library).

### Go

`.go`, `go.*`

- `go.mod` — module path, Go version, dependencies.
- `go.sum`.
- `.golangci.yml` — what's already enforced.
- The `internal/` boundary if present.

### Nix

`.nix`, `flake.*`

- `flake.nix` — inputs, outputs structure.
- `flake.lock` — pinned input revisions.
- The module file imports (often `default.nix` per directory).
- Any `lib/` directory for project-specific helpers.
- `nix flake check` config / output expectations.

### Java / Kotlin / Gradle

`.java`, `.kt`, `.gradle*`

- `build.gradle` / `build.gradle.kts` (root + per-module).
- `settings.gradle*`.
- `gradle.properties`.
- `pom.xml` if Maven.
- `.editorconfig` and `.ktlintrc` / `.checkstyle` for style enforcement.

### C / C++

`.c`, `.cpp`, `.h`, `.hpp`, `CMakeLists.txt`, `Makefile`

- `CMakeLists.txt` (root + per-target).
- `Makefile` if no CMake.
- `.clang-format`, `.clang-tidy`.
- `compile_commands.json` location to know how things actually build.

### Shell / Fish

`.sh`, `.bash`, `.fish`, `.zsh`

- `.shellcheckrc` if present.
- The shebang line (`#!/usr/bin/env bash` vs hardcoded).
- For fish: any `config.fish` or function-search path conventions.

### SQL / migrations

`.sql`, `migrations/*`

- ORM config if present (`prisma.schema`, `db/schema.rb`, etc.).
- Migration runner config (Flyway, Liquibase, db-migrate, knex, etc.).
- Existing migration naming convention (timestamp prefix, sequence number).

### Mixed-stack repos

Read every applicable block. Tauri apps (Rust + JS) need both Node and Rust must-reads. NixOS modules with embedded scripts need Nix and shell must-reads. Don't shortcut to one — pick all that apply.

## What to do when a manifest is missing

If a stack's expected manifest is absent (e.g. JS files but no `package.json`), flag it as `Open Question` in the final report:

> "No `package.json` found at repo root despite TS files in the diff — review assumed default `tsconfig.json` strictness; confirm the project's actual TS config."

Don't pretend it's there.

## What to read for a single-file diff

If the diff touches one file in a known stack, you don't need every block — read:

1. The standard always-read list (CLAUDE.md, AGENTS.md, README, the diff, comment style).
2. The stack's manifest (one file).
3. The single file's nearest sibling for idiom comparison.
4. Any direct dependency the changed code references (one level deep).

The full per-stack list is for non-trivial changes.

## Cost of skipping

The Hard Gate isn't ceremony — every reads-list entry has a real reason:

- Skipping `CLAUDE.md` / `AGENTS.md` → you flag rules that the project explicitly opts out of.
- Skipping the manifest → you flag idioms from the wrong framework version.
- Skipping the eslint / clippy config → you flag what the linter already catches, wasting reviewer attention.
- Skipping the comment-style guide → you flag comment patterns the project explicitly endorses.
- Skipping a sibling file → your "duplicate" finding misses the existing primitive.

If you're tempted to skip, ask why. The honest answers are "the file doesn't exist" (note it) or "it's huge, I'll skim" (don't — the relevant config is usually short).
