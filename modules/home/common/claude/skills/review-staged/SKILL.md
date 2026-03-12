---
name: review-staged
description: Review staged git changes against project conventions. Invoke with /review-staged before committing. Audits staged files for comment style, TypeScript types, ESLint errors, and CLAUDE.md compliance. Fixes what it can, reports what it cannot.
---

# Review Staged Changes

Audit all staged git changes against project conventions, fix what you can, and report the rest.

**Execute this skill directly.** Do not dispatch sub-agents (no `Task` tool, no `Explore`, no `adversarial-code-reviewer`). Read the files, review them, fix them, run checks -- all in this session.

## Workflow

### 1. Identify staged files

Run `git diff --cached --name-only` to get the list of staged files. If nothing is staged, tell the user and stop.

Filter to only source files: `*.ts`, `*.svelte`, `*.svelte.ts`, `*.css`, `*.js`. Ignore generated files (`$lib/paraglide/`, `node_modules/`, `build/`).

### 2. Read project guidance (HARD GATE -- do not skip)

Load these references before reviewing. **Do not propose or apply any fixes until this step is complete.**

- **CLAUDE.md** (project root) -- project conventions, architecture, SSR rules
- **comment-style** skill -- comment formatting, labels, section dividers, @component placement
- The staged file contents themselves (read every staged file completely)

After reading, write a brief summary of what the staged changes do (2-3 sentences). This confirms you understand the code before touching it. If you cannot summarize the changes, re-read until you can.

### 3. Review each file for issues

Check every staged file against these categories:

#### A. Comment style (FIX DIRECTLY)

Apply the **comment-style** skill. Check for violations of its formatting rules, label conventions, and documentation principles. The skill is the source of truth -- don't hardcode specific rules here.

#### B. TypeScript types (FIX WITHOUT REFACTORING)

- Loose types (`any`, untyped index signatures) that have a clear narrower alternative
- Missing type annotations on exported functions/parameters
- Unsafe casts that could use proper typed alternatives

Use judgment -- if narrowing a type requires refactoring the call sites, note it instead of fixing it.

#### C. Svelte/SvelteKit compliance (FIX DIRECTLY)

Check against **CLAUDE.md** project conventions, the **svelte-skills** (runes, data-flow, remote-functions, structure, template-directives), and the **svelte** and **daisyui** MCP servers to verify framework-specific correctness. Look for:

- Template issues (missing keys, wrong directive usage, deprecated APIs)
- Routing/i18n issues (raw paths instead of localized helpers)
- Invalid framework class names or component usage

The MCP servers are more current than any hardcoded list -- use them.

#### D. Architecture (NOTE ONLY -- requires human review before any fix)

Look for structural problems that cross module boundaries or affect the app's design:

- Wrong boundary crossings (server/client imports, env var misuse)
- Duplicated definitions that should be shared
- Incomplete implementations (missing i18n keys, unused props suggesting unfinished work)

These are presented in the results table for the user to decide on. Never fix these autonomously -- they often involve design decisions that need context beyond the diff.

#### E. Code quality & maintainability (NOTE ONLY -- requires human review before any fix)

Audit for dead code, separation of concerns, and unnecessary duplication:

- **Dead code** – if staged deletions leave orphaned imports, unused variables, or unreachable code in other files
- **Separation of concerns** – types, utilities, and functions in the correct modules (e.g., API logic in `services/`, not in components; types in their domain file, not scattered)
- **Unnecessary creation** – new methods, components, or classes that duplicate existing functionality or violate YAGNI/SOLID/DRY/KISS principles
- **Coherence** – ensure new additions follow existing patterns and don't introduce inconsistent abstractions

These are presented in the results table for the user to decide on. Never fix these autonomously -- they involve architectural judgment and may affect other parts of the codebase.

### 4. Apply fixes

For categories A, B, and C: edit the files directly. Use your best judgment. Keep changes minimal and focused -- don't refactor, don't change behavior.

**Scope guard:** Only touch lines that are part of the staged diff. Do not "improve" nearby code that wasn't changed. Do not revert existing styling choices. If a line wasn't staged, it doesn't exist for this review.

### 5. Run checks

Run `bun run check` (svelte-check) and `bun eslint src/` (ESLint on source). If either fails:

- Fix the errors
- Re-run
- Repeat until both pass

Then run `bun prettier --check` on the changed files. If formatting is off, run `bun prettier --write` on those files.

### 6. Verify fixes

After applying fixes and passing checks, **re-read every file you edited**. For each edit, confirm:

- The change does what you intended
- You didn't introduce new issues (broken imports, wrong indentation, mismatched brackets)
- You didn't touch lines outside the staged diff

If anything looks wrong, fix it now before presenting results.

### 7. Present results

Output a summary with three sections:

**Fixes applied** -- table with columns: File, What Changed, Why

**Issues found (not fixed)** -- table with columns: File, Issue, Problem, Potential Fix
These are category D items that need human decision.

**Check results** -- confirm `bun run check` and `bun eslint src/` pass.

**Commit message** -- draft a conventional commit message covering all changes. End with:

```
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

## Rules

- Stay scoped to staged files ONLY. Don't review or fix unstaged code.
- Don't refactor. Don't change behavior. Don't add features.
- If a fix would change component APIs or behavior, note it instead of fixing it.
- Load the `comment-style` skill before reviewing comments.
- Use MCP servers (`svelte`, `daisyui`) to verify framework-specific issues when unsure.
- If no issues are found, say so clearly. Don't invent problems.
