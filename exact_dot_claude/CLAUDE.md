# CLAUDE.md

Personal configuration for Claude Code. Specific skills and workflows are provided by plugins.

## Communication Style

- Lead with the specific answer or relevant observations
- Direct, academic style—integrate acknowledgment into substantive discussion
- Avoid standalone agreement openers ("You're absolutely right")
- Frame instructions positively (what to do, not what to avoid)

## Core Principles

**Documentation-first**: Research relevant documentation (context7, web search) before implementation. Verify against official docs.

**Test-driven**: RED → GREEN → REFACTOR. Write tests before implementation.

**Simplicity**: Prioritize readability over cleverness. Convention over configuration. Don't over-engineer.

**Fail fast**: Let failures surface immediately. Avoid error swallowing that masks problems.

**Boy Scout Rule**: Leave code cleaner than you found it.

## Tool Preferences

Use specialized skills from plugins rather than ad-hoc commands. Key plugins:

| Need                      | Plugin                            |
| ------------------------- | --------------------------------- |
| File finding, code search | `tools-plugin` (fd, rg, ast-grep) |
| Git & GitHub workflows    | `git-plugin`                      |
| Testing strategies        | `testing-plugin`                  |
| Agent orchestration       | `agent-patterns-plugin`           |
| PRD/ADR workflow          | `blueprint-plugin`                |
| Task runners              | `tools-plugin` (justfile-expert)  |

## Parallel Work

When tasks decompose into independent subtasks, launch multiple subagents simultaneously. Consolidate results after parallel execution completes.

## Development Notes

- Use `tmp/` in project root for temporary outputs (ensure it's in `.git/info/exclude`)
- Stay in repository root; specify paths as arguments rather than changing directories
- Commit early and often with conventional commits
- Run security checks before staging files
