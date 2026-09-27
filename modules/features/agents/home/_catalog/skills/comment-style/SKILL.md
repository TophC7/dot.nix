---
name: comment-style
description: Toph's code commenting conventions and label system. Use whenever writing, reviewing, or generating code in any language — JavaScript, TypeScript, Svelte, Rust, Python, Go, Java, Nix, CSS, shell, fish, yuck, anything. Governs how comments are formatted and labeled. Trigger for any code generation, review, refactor, or file creation. Even when the user doesn't mention comments explicitly, follow these conventions.
---

# Comment Style

Comments use a label system tied to a VS Code regex highlighter that color-codes by label. Correct formatting directly affects readability.

## Philosophy

- Don't comment obvious code. Explain "why," not "what."
- Keep comments short and scannable.
- Most comments are plain — no label. Labels are the exception, for things that need to visually pop. If every comment has a label, nothing stands out.
- Don't use em dash (`—`) in comments; don't substitute `--` either. Use natural sentence flow.

## Section Dividers

Use mirrored markers (the comment character doubled on each side):

```
// SECTION NAME //     JS, TS, Svelte, CSS, Rust, Java, Go, C, C++
## SECTION NAME ##     Fish, Python, Nix, Shell, YAML, TOML, Ruby
;; SECTION NAME ;;     Lisp, Clojure, Yuck, Scheme
-- SECTION NAME --     SQL, Haskell, Lua, Ada
```

Match the doubled character to the language's line-comment syntax. Plain dividers (`// ====` / `// ----`) are not picked up by the highlighter — don't use them.

## Labels

Use the label prefix at the start of a comment. Each gets a distinct highlight color.

- `TODO:` — work that needs doing
- `NOTE:` — non-obvious, easy to miss (use sparingly)
- `IDEA:` — potential improvement
- `INFO:` — reference info, links, docs
- `ABOUT:` — explanation of what a section/block does
- `???:` — uncertainty, needs investigation (any number of `?`)
- `FIXME:` / `FIX:` — known broken, needs a fix
- `BUG:` — documented bug
- `DEBUG:` — temporary, remove before shipping
- `HACK:` — ugly workaround, tech debt
- `REMOVE:` — marked for deletion
- `SKELETON:` — placeholder, not yet implemented
- `COMPONENT:` — component boundary note
- `CLAUDE:` — AI instruction. Sacred — obey absolutely and never remove or modify.

Block comments use a leading marker on continuation lines, matching the language's block-comment idiom:

```js
/* TODO: refactor this block
 * the state logic should move to a store */
```

```python
""" TODO: refactor this block
    the state logic should move to a store """
```

## Inline Markers

Small markers highlighted within any comment, no full label needed:

- `:D` — something clever or satisfying
- `!!!` — danger, critical warning
- `^^` — annotates the line directly above
- `<>` — list bullet inside comments (outside doc comments only)

```js
// this hack works perfectly :D

// do NOT change this order, breaks hydration !!!

const result = computeLayout(nodes);
// ^^ slow with 1000+ nodes

// reasons this works:
// <> layout engine caches intermediate results
// <> nodes sorted by depth first
// <> leaf nodes skip the full computation
```

## Doc Comments

For exported/public symbols, use the language's native doc-comment idiom at the top of the file or above the symbol. Keep it tight — one-line summary + parameters when non-obvious. Skip doc comments on internal helpers.

| Language     | Idiom                                                                                                               |
| ------------ | ------------------------------------------------------------------------------------------------------------------- |
| JS / TS      | `/** summary */` JSDoc; `@param` for non-obvious inputs; no `@description`, `@summary`, or `@returns` on components |
| Svelte       | `<!-- @component summary @param ... -->` at top of file                                                             |
| Rust         | `///` for items, `//!` for module-level                                                                             |
| Python       | `"""summary"""` docstring; types in signatures, not in docstring                                                    |
| Go           | `// Symbol does X.` (godoc convention, sentence-cased, starts with the symbol name)                                 |
| Nix          | `# summary` line above the binding                                                                                  |
| Shell / Fish | `# summary` line above the function                                                                                 |

## Anti-patterns

- Commenting _what_ the code does when names already say it (`// loop through items` above a `for`).
- Labels on every line — drowns the highlighter; nothing stands out.
- `TODO:` for things that already work fine. Use `NOTE:` or `IDEA:` instead.
- Block-of-essay comments paraphrasing the function below. One line of WHY beats five lines of WHAT.
- Misleading or stale comments. Edit them when the code changes; delete them when they no longer apply.
