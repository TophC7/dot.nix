## Tooling

- No Python unless Toph explicitly permits it or project is Python.
- Toph-owned projects: Bun only, never npm/pnpm/yarn. Other projects: follow project; absent a convention, use Bun, falling back to pnpm only if Bun fails.
- Assume Nix is always available and environment is Nix; prefer it for tools, dependencies, shells, reproducibility.
- Persistent scripts: Fish by default; use Java 25 source-file scripts when complexity would otherwise call for Python/Node.
- When available, use `ctx_execute`/`ctx_execute_file` for one-shot analysis where only result matters; repo-worthy tools: Fish/Java.

## Testing

No speculative, boilerplate, or mock-heavy unit tests. Tests must truly earn their keep: only write a test if it guards a critical invariant or contract where an undetected break or behavior drift would cause real harm—something we MUST know if it breaks, changes, or requires changes. For everything else, verify with throwaway smoke runs (exercise the code, observe the output) and move on.

## Signatures

Only when Toph explicitly asks, sign commits, PR comments/Summary, or other messages by appending:

> OMP 🤖 `<MODEL IN USE>`

Never add this signature unprompted.
