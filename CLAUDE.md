# CLAUDE.md

Chezmoi dotfiles repository with cross-platform development environment configuration.

## Chezmoi Configuration

This repository uses [chezmoi](https://www.chezmoi.io/) for dotfiles management.

### Quick Reference
- **Source directory**: `~/.local/share/chezmoi/` (always edit here)
- **Target locations**: `~/.*` (never edit directly)
- **Essential commands**: `chezmoi diff`, `chezmoi apply --dry-run`, `chezmoi apply`

### Claude Code Skills & Plugins
This repository includes **Skills** (17 total) - automatically discovered capabilities that Claude uses based on context:

**Core Development Tools:**
- **Chezmoi Expert** - Comprehensive chezmoi guidance (file management, templates, cross-platform configs)
- **Shell Expert** - Shell scripting, CLI tools, automation, and cross-platform scripting
- **fd File Finding** - Fast file search with smart defaults and gitignore awareness
- **rg Code Search** - Blazingly fast code search with ripgrep and regex patterns
- **Git Workflow** - Preferred git patterns including branching, commits, and validation

**GitHub Actions Integration:**
- **Claude Code GitHub Workflows** - Workflow design, PR reviews, issue triage, and CI auto-fix
- **GitHub Actions MCP Configuration** - MCP server setup, tool permissions, and multi-server coordination
- **GitHub Actions Auth & Security** - Authentication methods, secrets management, and security best practices

**Editor & Languages:**
- **Neovim Configuration** - Lua configuration, plugin management, LSP setup, and AI integration
- **Python Development** - Modern Python with uv, ruff, pytest, and type hints
- **Rust Development** - Memory-safe systems programming with cargo and modern tooling
- **Node.js Development** - JavaScript/TypeScript with Bun, Vite, Vue 3, and Pinia
- **C++ Development** - Modern C++20/23 with CMake, Conan, and Clang tools

**Infrastructure & DevOps:**
- **Container Development** - Docker, multi-stage builds, and 12-factor apps
- **Kubernetes Operations** - K8s cluster management and debugging
- **Infrastructure Terraform** - Infrastructure as Code with HCL and state management
- **Embedded Systems** - ESP32/ESP-IDF, STM32, FreeRTOS, and real-time systems

Skills are located in `.claude/skills/` and are automatically loaded by Claude when relevant. See `.claude/skills/README.md` for details.

This repository also provides **Plugins** - installable packages distributed via the Claude Code marketplace:
- **Dotfiles Toolkit** - 14 specialized agents and 20+ commands for development workflows, code quality, and infrastructure operations

Plugins are located in `plugins/` and can be installed via the marketplace system. See `plugins/README.md` for details.

## Linting Commands

```bash
shellcheck **/*.sh                    # Shell scripts
luacheck private_dot_config/nvim/lua  # Neovim config
actionlint                            # GitHub Actions
brew bundle check --file=Brewfile     # Brewfile integrity
pre-commit run --all-files            # Run all pre-commit hooks
```

### Secret Scanning
```bash
detect-secrets scan --baseline .secrets.baseline  # Scan for new secrets
detect-secrets audit .secrets.baseline            # Review flagged secrets
pre-commit run detect-secrets --all-files         # Run via pre-commit
```

## Key Files & Directories

### Configuration Files
- `private_dot_config/nvim/` - Neovim setup with lazy.nvim
- `private_dot_config/fish/` - Fish shell with cross-platform paths
- `Brewfile` - Homebrew package definitions
- `dot_default-*-packages` - Tool package lists (cargo, npm, uv)

## Cross-Platform Support

- Templates for platform-specific configurations
- CPU and architecture detection
- The **Chezmoi Expert** Skill provides automatic guidance for template syntax and cross-platform patterns

## Tools

- **mise**: Tool version management (`.config/mise/config.toml`)
- **Fish**: Primary shell with Starship prompt
- **Neovim**: Editor with LSP, formatting, debugging
- **Homebrew**: Cross-platform package management

## Documentation Requirements
**ALWAYS check documentation before implementing changes or features.**

### Implementation Checklist
Before implementing any changes or features, complete this checklist:

1. **Read relevant documentation sections thoroughly**
2. **Verify syntax and parameters** in official documentation before coding
3. **Check for breaking changes** and version compatibility requirements
4. **Review best practices** and recommended patterns in the tool's documentation
5. **Validate configuration options** against current documentation versions
6. **Check for deprecated features** that should be avoided
7. **Confirm implementation details match current best practices**

### Critical Documentation Sources
- Tool-specific documentation (mise, Fish, Neovim, Homebrew, chezmoi)
- GitHub Actions documentation for workflow modifications
- Platform-specific guides for cross-platform compatibility
- Security documentation for secrets handling and API token management

## CI Pipeline

Multi-platform testing (Ubuntu/macOS) with linting → build stages in `.github/workflows/smoke.yml`

## Security

- API tokens in `~/.api_tokens` (not in repo)
- Private files use `private_` prefix
- No secrets committed
- **detect-secrets** pre-commit hook prevents accidental secret commits
- **TruffleHog** scans for leaked credentials in git history
- Both tools run automatically on commit via pre-commit hooks
