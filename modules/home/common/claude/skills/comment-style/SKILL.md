---
name: comment-style
description: Toph's code commenting conventions and style guide. Use this skill whenever writing, reviewing, or generating code in any language — JavaScript, TypeScript, Svelte, Rust, Java, Nix, CSS, shell scripts, fish, yuck, or any other language. This skill governs how comments should be written, formatted, and labeled. Trigger this skill for ANY code generation, code review, refactoring, or file creation task. Even if the user doesn't mention comments explicitly, follow these conventions whenever producing code. Also use when the user asks about commenting style, code documentation, or how to annotate code.
---

# Toph's Comment Style Guide

These are Toph's commenting conventions. Follow them in ALL code output. They are designed around a custom VS Code regex highlighter that colors comments by label, so correct formatting matters — it directly affects readability.

## Core Philosophy

1. Don't explain obvious code. If the code reads clearly, it needs no comment.
2. Reserve verbose explanations for complex or unusual logic — algorithms, workarounds, non-obvious side effects, "why" not "what."
3. Comments are for humans scanning fast. Keep them short, punchy, and scannable.
4. Use the label system. Labels aren't decoration — they're a visual triage system powered by color-coded highlighting.
5. Most comments should be plain — no label. Labels are reserved for comments that genuinely deserve visual highlighting. If every comment is highlighted, nothing stands out.
6. Do not use em dash (`—`) in comments. Prefer natural sentence flow that doesn't cut off abruptly. Do not circumvent this rule with '--'.

---

## Labels vs Plain Comments

This is the most important rule: NOT every comment needs a label. A plain comment is the default. Labels are the exception — use them only when the comment deserves to visually pop in the editor.

Ask yourself: "Would a reader need this to jump out at them while scanning?" If no, it's a plain comment.

BAD — label overuse (everything is highlighted, nothing stands out):

```js
// NOTE: uses OTP auth, not passwords
// NOTE: tokens live in httpOnly cookies
import { command } from '$app/server'

// NOTE: returns otpId even if user doesn't exist
export const requestOTP = command(...)

// NOTE: on success sets the httpOnly cookie
export const verifyOTP = command(...)

// NOTE: creates user then sends OTP
export const register = command(...)
```

GOOD — labels only where they earn it:

```js
// uses OTP auth, not passwords
// auth tokens live in httpOnly cookies — never exposed to browser JS
import { command } from '$app/server'

// returns otpId even if user doesn't exist (PB enumeration protection)
export const requestOTP = command(...)

// on success sets the httpOnly cookie. Caller must invalidateAll()
export const verifyOTP = command(...)

// NOTE: PB requires a password even for OTP-only — generate a throwaway one
const password = crypto.randomUUID()
```

In the GOOD example, only the PocketBase password quirk gets NOTE: because it's genuinely surprising and a reader needs to understand why a password exists in an OTP-only flow. Everything else is just normal context that reads fine as a plain comment.

---

## Section Dividers

Use mirrored comment markers as section dividers to visually break up a file into logical regions. These render with special highlight colors.

```
// SECTION NAME //     JS, TS, Svelte, CSS, Rust, Java, Go, C
## SECTION NAME ##     Fish, Python, Nix, Shell, YAML, TOML
;; SECTION NAME ;;     Lisp, Clojure, Yuck
```

The mirrored marker doubles the comment character on each side — `//` doubles `/`, `##` doubles `#`, `;;` doubles `;`. This is what the highlighter matches.

```js
// IMPORTS //

import { foo } from "./foo";
import { bar } from "./bar";

// STATE //

let count = 0;
let active = false;

// HANDLERS //

function onClick() { ... }
```

```fish
## ALIASES ##

abbr -a ls eza
abbr -a s ssh

## FUNCTIONS ##

function greet
    echo "hello"
end
```

---

## Labeled Comments

Labels go on both line comments and block comments. Each label gets a distinct background/text color in the editor, so using the right label matters.

### Label reference

Brown/amber group — work tracking:

- TODO: — Work that still needs doing

Yellow group — context:

- NOTE: — Something non-obvious, or easy to miss

Blue group — ideas:

- IDEA: — Potential improvements, not yet committed to

Green group — supplementary:

- INFO: — Supplementary/reference info, links, docs

Purple group — explanations and unknowns:

- ABOUT: — Explanation of what a section/block does
- ???: — Confusion, uncertainty, needs investigation (can use any number of question marks)

Red/rose group — problems and debt:

- FIXME: — Known broken thing that needs a fix
- FIX: — Same as FIXME, shorthand
- BUG: — Documented bug
- DEBUG: — Temporary debug code, remove before shipping
- HACK: — Ugly workaround, tech debt
- REMOVE: — Marked for deletion

Terracotta group — structure:

- SKELETON: — Placeholder/scaffold structure, not yet implemented
- COMPONENT: — Marks a component boundary or component-level note

Special — AI instructions:

- CLAUDE: — Instructions for AI assistants. These are sacred. AI must obey them absolutely and never remove or modify them.

### Format

Line comments:

```js
// TODO: add error handling for edge case
// NOTE: this runs on every render, intentionally
// BUG: crashes when input is empty string
// ???: why does this need a 50ms delay?
```

Block comments (for multi-line). Use a leading asterisk on every continuation line:

```js
/* TODO: refactor this whole block
 * it's getting unwieldy and the state
 * logic should move to a store */

/* ABOUT: Authentication Flow
 * handles OAuth redirect, token refresh,
 * and session persistence */
```

---

## Special Inline Markers

These are small markers that get highlighted within any comment (line or block). Use them for emphasis without a full label.

The :D marker (warm/bold highlight) — marks something fun, clever, or satisfying.

The triple-bang marker (red/bold highlight) — danger, critical warning, pay attention.

The caret-caret marker (gold/bold highlight) — points to the line of code directly above, annotates it.

The angle-bracket-pair marker (orange and pink highlight) — used as a list bullet inside comments, outside of JSDoc only.

```js
// this hack actually works perfectly :D

// do NOT change this order — breaks hydration !!!

const result = computeLayout(nodes);
// ^^ can be slow with 1000+ nodes

// reasons this works:
// <> the layout engine caches intermediate results
// <> nodes are sorted by depth first
// <> leaf nodes skip the full computation
```

Note: the angle bracket pair is used only outside of JSDoc blocks — inside regular comments as a visual bullet point.

---

## Component Documentation (Svelte)

For Svelte components, use the HTML comment with @component at the top of the file. This is Svelte's native doc comment format. Keep it tight — what the component does and what it needs.

```svelte
<!--
  @component
  ColorPicker — inline color selection with preset swatches

  @param colors - array of hex color strings
  @param selected - currently active color
  @param onSelect - callback when a color is picked
-->
```

For plain JS/TS modules (non-Svelte), use standard JSDoc at the top of the file:

```ts
/**
 * validateEmail — checks an email string against RFC 5322
 *
 * @param email - raw email string to validate
 */
```

Rules:

- One-liner summary of what the component/module is.
- Use @param for props/inputs — name and brief description, types if not obvious from TS.
- No @returns on components (the template is the output).
- No @description, @summary, or other redundant tags.
- No doc comments on utility functions unless they're exported and non-obvious.
- No doc comments on internal/private helpers — use a line comment if anything.

---

## What NOT To Do

Don't comment obvious code:

```js
// BAD:
const count = 0; // set count to zero
items.forEach((item) => process(item)); // loop through items

// GOOD: (no comment needed, the code is clear)
const count = 0;
items.forEach((item) => process(item));
```

Don't use plain dividers:

```js
// BAD:
// ========================
// SECTION
// ========================

// GOOD:
// SECTION //
```

Don't write essay comments:

```js
// BAD:
// This function takes a user object and extracts the email
// property from it, then validates the email using a regex
// pattern to ensure it matches the standard email format
// before returning the validated result to the caller.
function validateEmail(user) { ... }

// GOOD:
// NOTE: regex doesn't cover all RFC 5322 edge cases
function validateEmail(user) { ... }
```

Don't use labels you don't mean:

```js
// BAD:
// TODO: this works fine (then it's not a TODO)

// GOOD:
// NOTE: this works but could be cleaner
// IDEA: extract into a shared util
```

Don't put labels on every comment. Most comments are plain:

```js
// BAD — label spam:
// NOTE: clears the auth cookie
// NOTE: caller must redirect after this
export const logout = command(...)

// GOOD — plain comments, no label needed:
// clears auth cookie only. Caller must redirect or invalidateAll()
export const logout = command(...)
```

---

## Quick Reference

```
// SECTION NAME //          section divider (JS, TS, CSS, Rust, etc.)
## SECTION NAME ##          section divider (Fish, Python, Nix, Shell, etc.)

// TODO: ...                needs doing
// NOTE: ...                surprising/non-obvious (use sparingly)
// IDEA: ...                potential improvement
// INFO: ...                reference/supplementary
// ABOUT: ...               what this does
// ???: ...                 uncertain / needs investigation
// FIXME: / FIX: ...        known issue, needs fix
// BUG: ...                 documented bug
// DEBUG: ...               temp debug code
// HACK: ...                ugly workaround
// REMOVE: ...              delete this soon
// SKELETON: ...            placeholder structure
// COMPONENT: ...           component boundary note
// CLAUDE: ...              AI instruction (sacred, never remove)

// something clever :D      satisfying / fun
// critical warning !!!     danger
const x = tricky();
// ^^ about that line       annotates the line above
// <> first reason          list bullet (outside JSDoc only)
// <> second reason

<!-- @component ... -->      top-of-file Svelte doc comment
/** summary */              top-of-file JSDoc for plain JS/TS modules
```
