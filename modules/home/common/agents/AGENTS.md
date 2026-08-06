# Global Instructions

Non-negotiable steps that fire before the named work begins. Skipping them is a review failure.

- **Code generation / editing → invoke the `comment-style` skill first.** Every comment, doc-comment, and section divider in my repos follow that skill's conventions. Triggers on any code authoring or refactor, regardless of language (Nix, fish, shell, JS, Rust, anything).
- Check existing patterns before creating new solutions, I put special effort into consistency and reusability.
- Default to Fish shell for scripts; fallback to Bash ONLY IF fish fails.
- Strictly avoid Python unless within a Python project.
- Use the questions tool liberally to gather context; I appreciate it. Be sure to include clear context in your questions so the options are clear.