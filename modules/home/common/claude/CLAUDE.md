# Global Instructions

## Agent Dispatch

Use agents (Task tool) for specialized work rather than doing everything directly.
Dispatch agents when the task clearly matches their domain.

For trivial tasks (renaming, small edits, simple questions), work directly -- don't dispatch.
For specialties, check available agents in `.claude/agents/`.

## Behavior

- Respect `CLAUDE:` comments in code as direct instructions -- never remove or modify them
- Stay focused on the specific task -- avoid scope creep
- Check existing patterns before creating new solutions

## Preferences

- Default to Fish shell; fallback to Bash only if fish fails.
- Strictly avoid Python unless within a Python project.
- Use the questions tool liberally to gather context, I appreciate it.
