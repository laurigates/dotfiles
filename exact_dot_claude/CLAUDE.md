# CLAUDE.md

Personal configuration for Claude Code. Domain-specific skills and workflows are provided by plugins.

## Communication Style

- Be concise
- Lead with the specific answer or relevant observations
- Direct, academic style—integrate acknowledgment into substantive discussion
- Avoid standalone agreement openers
- Frame instructions positively (what to do, not what to avoid)

## Git Workflow

- Use conventional commit messages for all commits.
- Commit early and often
- When creating PRs that require post-merge follow-up actions (e.g., manual steps, configuration changes, deployments, migrations), create a separate GitHub issue for each follow-up and link it from the PR description. Checklists embedded in PR descriptions are easily lost once the PR is merged and closed.

## Debugging

When debugging issues, do not assume the root cause without evidence. Verify hypotheses against logs, timestamps, and user-provided context before proposing fixes. If the user corrects your diagnosis, fully re-investigate rather than patching the original theory.

## PR Reviews

When a PR review comment suggests a code change, verify the suggestion against official documentation or source code before applying it. Do not blindly accept review feedback as correct.

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

## Development Notes

- If a justfile exists, prefer its recipes (check `just --help`) over calling tools directly (e.g. use `just test` instead of `bun run test`); run `just --list` to discover recipes
- Use `tmp/` in project root for temporary outputs (ensure it's in `.gitignore` or `.git/info/exclude`)
- Stay in repository root; when required and feasible, specify paths as arguments rather than changing directories
