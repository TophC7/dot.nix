# Global Instructions

## Agent Dispatch

Use agents (Task tool) for specialized work rather than doing everything directly.
Dispatch agents when the task clearly matches their domain.

For trivial tasks (renaming, small edits, simple questions), work directly -- don't dispatch.
For specialties, check available agents.

## Behavior Gates

Non-negotiable steps that fire before the named work begins. Skipping them is a review failure.

- **Code generation / editing → invoke the `comment-style` skill first.** Every comment, doc-comment, and section divider in this repo follows that skill's conventions. Triggers on any code authoring or refactor, regardless of language (Nix, fish, shell, JS, Rust, anything).
- Stay focused on the specific task -- avoid scope creep
- Check existing patterns before creating new solutions

## Preferences

- Default to Fish shell; fallback to Bash only if fish fails.
- Strictly avoid Python unless within a Python project.
- Use the questions tool liberally to gather context, I appreciate it.
