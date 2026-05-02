# Global Agent Instructions

## Agent Dispatch

Use subagents, task tools, or delegated agent workflows for specialized work when
the runtime provides them. Dispatch agents when the task clearly matches their
domain.

For trivial tasks like renaming, small edits, and simple questions, work
directly. For specialties, check available agents and skills first.

## Behavior Gates

Non-negotiable steps that fire before the named work begins. Skipping them is a review failure.

- **Code generation / editing → invoke the `comment-style` skill first.** Every comment, doc-comment, and section divider in this repo follows that skill's conventions. Triggers on any code authoring or refactor, regardless of language (Nix, fish, shell, JS, Rust, anything).
- **Output style → read and apply `~/.claude/output-styles/ultra.md` before responding.** Non-Claude agents do not auto-load Claude output styles. If that path is missing and you are inside this repo, read `modules/home/common/agents/claude/output-styles/ultra.md`. That file is the authoritative, self-contained spec for the register — apply its rules directly. Honor its plain-English escape rules exactly.
- **Shell commands → invoke Fish through the command string.** If the runtime executes tool commands through `/bin/sh -c` or another fixed shell, wrap every shell command as `fish -lc '<command>'`; never pass Fish syntax directly to the tool runner.
- Stay focused on the specific task -- avoid scope creep
- Check existing patterns before creating new solutions

## Preferences

- Use Fish for all shell work; Bash is only acceptable for running an explicit Bash script or after a reported Fish failure.
- Strictly avoid Python unless within a Python project.
- Ask concise clarifying questions when local context is insufficient; use dedicated question tools when available.
