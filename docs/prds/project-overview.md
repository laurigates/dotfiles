---
id: PRD-001
created: 2026-04-07
modified: 2026-04-07
status: Draft
version: "1.0"
relates-to: []
github-issues: []
name: blueprint-derive-prd
---

# Dotfiles — Product Requirements Document

## Executive Summary

### Problem Statement
Setting up a consistent, reproducible development environment across multiple machines (macOS, Linux) is time-consuming and error-prone without a managed dotfiles system. Manual configuration drifts over time, tool versions diverge, and context-specific settings (secrets, platform differences) are difficult to maintain securely.

### Proposed Solution
A chezmoi-managed dotfiles repository that declaratively configures the full development environment: shell (Zsh), editor (Neovim), CLI tools, package management (Homebrew + mise), and AI tooling (Claude Code + MCP servers). Templates handle cross-platform differences; secret files use the `private_` prefix; exact-match directories ensure no orphaned config files.

### Business Impact
- **Faster machine setup**: New machines fully configured via `chezmoi init && chezmoi apply` in minutes
- **Consistency**: Identical tool versions, key bindings, editor settings, and shell behavior across all machines
- **AI-augmented workflow**: Claude Code with plugins and MCP servers available consistently everywhere
- **Security**: Secrets managed via `~/.api_tokens` (never committed); gitleaks scanning on every commit

## Stakeholders & Personas

### Stakeholder Matrix
| Role | Name | Responsibility |
|------|------|----------------|
| Owner / Developer | Lauri Gates | All decisions, implementation, maintenance |

### User Personas

#### Primary: Developer (Lauri Gates)
- **Description**: Software developer working across multiple macOS machines, occasionally Linux
- **Needs**: Consistent Zsh environment, fast Neovim with LSP, reproducible tool versions, Claude Code with full plugin ecosystem
- **Pain Points**: Re-configuring tools on new machines; config drift; manual MCP server setup; forgetting which Neovim plugins are in use
- **Goals**: `chezmoi apply` fully restores the expected environment; AI tooling works out of the box on any machine

## Functional Requirements

### Core Features

| ID | Feature | Description | Priority |
|----|---------|-------------|----------|
| FR-001 | Chezmoi dotfile management | Source-controlled dotfiles applied via `chezmoi apply`; templates for cross-platform differences | P0 |
| FR-002 | Zsh shell configuration | Starship prompt, FZF integration, syntax highlighting, autosuggestions, vi-mode, completions | P0 |
| FR-003 | Neovim configuration | Lua-based config with lazy.nvim, Treesitter, LSP, completion (blink.cmp), formatters, linters | P0 |
| FR-004 | Tool version management | mise manages Node, Python, Go, Rust, Bun and CLI tools via pipx/aqua backends | P0 |
| FR-005 | Package management | Homebrew Brewfile with profile-based package selection (core, dev, infra, gui) | P0 |
| FR-006 | Claude Code integration | Plugins from laurigates/claude-plugins; MCP server registry in `.chezmoidata.toml`; per-project `.mcp.json` | P1 |
| FR-007 | Secret management | API tokens in `~/.api_tokens` (sourced by mise); private files use `private_` prefix; gitleaks scanning | P0 |
| FR-008 | Cross-platform templates | Chezmoi templates handle macOS/Linux differences for shell config, tool paths, platform-specific packages | P1 |
| FR-009 | CI/CD pipeline | Smoke tests (Ubuntu/macOS), linting (shellcheck, luacheck, actionlint, stylua), secret scanning | P1 |
| FR-010 | AI-assisted development | Claude Code claude.yml workflow for AI-assisted PRs/issues; auto plugin install in CI | P2 |
| FR-011 | MCP server management | Dynamic MCP config from `.chezmoidata.toml`; enable/disable servers; per-project overrides | P1 |
| FR-012 | Task runner | justfile with standard recipes: apply, diff, lint, test, plugin management, tool updates | P1 |

### User Stories

- As a developer, I want `chezmoi apply` to fully configure a new machine so I can start working in under 10 minutes
- As a developer, I want Neovim LSP to work for my primary languages (Lua, Python, Shell, Go) without manual setup
- As a developer, I want Claude Code with all my plugins available on every machine without re-installing
- As a developer, I want to enable/disable MCP servers in one config file that propagates everywhere
- As a developer, I want my shell to have consistent key bindings, aliases, and completions across machines
- As a developer, I want secrets kept out of git while still being accessible to tools that need them

## Non-Functional Requirements

### Performance
- Shell startup time: < 500ms (measured by `time zsh -i -c exit`)
- `chezmoi apply` idempotent: no changes on second run when environment is current
- Neovim startup: < 200ms for daily use

### Security
- No secrets in git — API tokens, credentials via `~/.api_tokens`
- Private files use `private_` chezmoi prefix (mode 600)
- gitleaks on every commit via pre-commit hook
- detect-secrets baseline maintained in `.secrets.baseline`

### Reliability
- Smoke test CI validates setup on Ubuntu and macOS
- Docker-based smoke test for isolated environment testing
- Pre-commit hooks prevent broken commits (shellcheck, luacheck, actionlint)

### Compatibility
- **Primary**: macOS (darwin/arm64) — Apple Silicon
- **Secondary**: Ubuntu/Debian Linux (CI, VMs)
- **Future**: NixOS (ADR-0013 documents intent)

## Technical Considerations

### Architecture
- **Chezmoi** as the single source of truth for all dotfiles
- **Templates** (`.tmpl` suffix) for platform/arch-specific config
- **exact_** prefix for directories where orphaned files should be removed (e.g., `exact_dot_claude/`)
- **private_** prefix for secret/sensitive config files (chmod 600)
- **mise** for all runtime tool versions; backends: `pipx:` for Python CLIs, `aqua:` for binaries
- **Brewfile** with profile-based package selection via `.chezmoidata/profiles.toml`

### Key Configuration Files
- `.chezmoidata.toml` — MCP servers, uv_tools, platform data
- `.chezmoidata/packages.toml` — Profile-based Homebrew package registry
- `.chezmoidata/profiles.toml` — Profile activation flags
- `dot_zshrc.tmpl` — Zsh config (template)
- `private_dot_config/mise/config.toml.tmpl` — mise tools and tasks
- `private_dot_config/nvim/` — Neovim Lua configuration
- `exact_dot_claude/` — Claude Code config (exact-match semantics)

### Dependencies
- chezmoi, mise, Homebrew (macOS), git
- Neovim 0.9+, Lua 5.1+
- Claude Code CLI (for AI-assisted development features)

### Integration Points
- GitHub (CI/CD, Claude Code workflows, issue/PR automation)
- Claude Code plugin marketplace (laurigates/claude-plugins)
- MCP servers: context7, sequential-thinking, pal, playwright, github

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| New machine setup time | < 10 min | Manual timing |
| Shell startup time | < 500ms | `time zsh -i -c exit` |
| CI smoke test pass rate | 100% | GitHub Actions |
| Pre-commit hook pass rate | 100% on main | Git log |

## Scope

### In Scope
- Zsh shell configuration (prompts, plugins, completions, key bindings)
- Neovim editor configuration (Lua, plugins, LSP, formatters)
- Tool version management via mise
- Package management via Homebrew
- Claude Code configuration (plugins, skills, rules, MCP servers)
- Git configuration (delta, conventional commits, pre-commit hooks)
- CI/CD pipeline (smoke tests, linting, security scanning)
- Cross-platform templates (macOS primary, Linux secondary)
- Secret management patterns

### Out of Scope
- GUI application configuration (beyond Brewfile cask installs)
- Windows/WSL support
- NixOS full support (intent documented in ADR-0013, not yet implemented)
- Team/organization rollout (solo project)

## Timeline & Phases

### Current Phase: Active Development
Ongoing improvements across all areas: AI tooling expansion, new tool integrations, Claude Code plugin development, performance optimizations.

### Roadmap
| Phase | Focus | Status |
|-------|-------|--------|
| Foundation | Chezmoi, Zsh, Neovim, mise, Homebrew | Complete |
| AI Integration | Claude Code, plugins, MCP servers, claude.yml | Active |
| Blueprint | Blueprint development structure, PRDs, ADRs | Active |
| NixOS | Declarative system configuration (ADR-0013) | Planned |

---
*Generated from existing documentation via /blueprint:derive-prd*
*Review and update as project evolves*
