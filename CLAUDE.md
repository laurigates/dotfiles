# CLAUDE.md

Chezmoi dotfiles repository with cross-platform development environment configuration.

## Chezmoi Quick Reference

- **Source directory**: `~/.local/share/chezmoi/` (always edit here)
- **Target locations**: `~/.*` (never edit directly)
- **Essential commands**: `chezmoi diff`, `chezmoi apply --dry-run`, `chezmoi apply`
- **Cross-platform**: Templates handle OS/arch differences; Chezmoi Expert skill provides guidance

### Claude Code Directory (exact_dot_claude/)

The `.claude` directory is managed via `exact_dot_claude/` with exact-match semantics (orphaned files auto-removed). Run `chezmoi apply -v ~/.claude` after changes. Do NOT create `.claude/` in the chezmoi source directory — it's gitignored and used as a runtime directory.

## Plugins

Managed in [laurigates/claude-plugins](https://github.com/laurigates/claude-plugins). Use `just plugins-*` recipes for bulk management.

## MCP Servers

Managed per-project in `.mcp.json`. Registry of available servers in `.chezmoidata.toml` under `[mcp_servers]`. Use `/configure:mcp` for guided setup.

## Linting

### mise tasks (recommended):
```bash
mise run lint          # All linters (shell, lua, actions, Brewfile)
mise run lint:shell    # Shell scripts only
mise run lint:lua      # Neovim config only
mise run lint:actions  # GitHub Actions only
mise run test          # All tests (linting + docker)
```

### Direct commands:
```bash
shellcheck **/*.sh                    # Shell scripts
luacheck private_dot_config/nvim/lua  # Neovim config
actionlint                            # GitHub Actions
brew bundle check --file=Brewfile     # Brewfile integrity
pre-commit run --all-files            # All pre-commit hooks
```

### Secret scanning:
```bash
detect-secrets scan --baseline .secrets.baseline
detect-secrets audit .secrets.baseline
pre-commit run detect-secrets --all-files
```

## Key Files & Directories

- `.chezmoidata.toml` — Template data (MCP servers, uv_tools, shell completions)
- `dot_zshrc.tmpl`, `dot_zshenv.tmpl` — Zsh shell configuration
- `private_dot_config/mise/config.toml.tmpl` — mise tool versions and tasks
- `private_dot_config/nvim/` — Neovim setup (see `nvim/CLAUDE.md`)
- `private_dot_config/private_fish/` — Fish shell (experimental)
- `Brewfile` — Homebrew packages
- `justfile` — Task runner recipes (`just --list`)
- `mise.lock` — Reproducible tool versions

## Tools

- **just** — Task runner; `justfile` in repo root
- **mise** — Tool version management; backends: `pipx:`, `aqua:`
- **Zsh** — Primary shell with Starship prompt
- **Neovim** — Editor with LSP, formatting, debugging
- **Homebrew** — Package management (bootstrap and system tools)

## CI Pipeline

- **smoke.yml** — Multi-platform (Ubuntu/macOS) linting and build
- **claude.yml** — AI-assisted dev with auto plugin install from [laurigates/claude-plugins](https://github.com/laurigates/claude-plugins)

## Blueprint Documentation

Blueprint v3.2.0 manages project documentation and rules.

- **PRD**: `docs/prds/project-overview.md` — Feature requirements and scope
- **ADRs**: `docs/adrs/` — 16 Architecture Decision Records ([index](docs/adrs/README.md))
- **PRPs**: `docs/prps/` — Implementation plans (fish, NixOS, sketchybar)
- **Manifest**: `docs/blueprint/manifest.json` — Configuration and task registry
- **Commands**: `/blueprint:status`, `/blueprint:execute`, `/blueprint:derive-plans`

## Sub-documentation

- `exact_dot_claude/CLAUDE.md` — Claude Code design and directory structure
- `exact_dot_claude/commands/CLAUDE.md` — Slash commands guide
- `exact_dot_claude/skills/CLAUDE.md` — Skills system
- `private_dot_config/CLAUDE.md` — Application configuration
- `private_dot_config/nvim/CLAUDE.md` — Neovim configuration
- `scripts/CLAUDE.md` — Maintenance scripts
- `docs/blueprint/README.md` — Blueprint structure overview

## Security & Release

See `.claude/rules/security.md` and `.claude/rules/release-please.md`. Quick: API tokens in `~/.api_tokens`, private files use `private_` prefix, never manually edit `CHANGELOG.md`.
