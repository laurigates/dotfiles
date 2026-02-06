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

## Tool Installation Priority

When installing new tools, prefer earlier options:

1. **mise** — primary tool manager for runtimes and CLI tools
   - Core: language runtimes (Python, Node, Go, Rust, Bun)
   - `pipx:` backend: Python CLI tools (runs via uvx)
   - `aqua:` backend: standalone CLI binaries with checksum verification
2. **uv tool install** — Python tools as isolated packages
3. **uv pip install** — Python libraries into active environment
4. **bun install -g** — JavaScript/TypeScript global packages
5. **cargo install** — Rust tools not available via aqua
6. **go install** — Go tools not available via aqua
7. **brew install** — system packages, GUI apps (casks), build dependencies; last resort for CLI tools

## Development Environment

- **Shell**: Zsh with Starship prompt and FZF integration
- **Editor**: Neovim with lazy.nvim and Mason LSP
- **Task runner**: `just` for project tasks; `mise run` for dotfiles tasks
- **Version control**: git with delta (diff pager), lazygit (TUI), gh (GitHub CLI)
- **Search**: rg (ripgrep), fd, ast-grep, fzf
- **Platform**: macOS (darwin/arm64) with Homebrew
- **Dotfiles**: chezmoi — always edit source at `~/.local/share/chezmoi/`, never target files
- **API tokens**: `~/.api_tokens` (sourced by mise), never committed

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

- Prefer `just <recipe>` for project tasks; run `just --list` to discover recipes
- Use `tmp/` in project root for temporary outputs (ensure it's in `.git/info/exclude`)
- Stay in repository root; specify paths as arguments rather than changing directories
- Commit early and often with conventional commits (drives release-please automation)
- Run security checks before staging files
