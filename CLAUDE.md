# CLAUDE.md

Chezmoi dotfiles repository with cross-platform development environment configuration.

## Chezmoi Configuration

This repository uses [chezmoi](https://www.chezmoi.io/) for dotfiles management.

### Quick Reference
- **Source directory**: `~/.local/share/chezmoi/` (always edit here)
- **Target locations**: `~/.*` (never edit directly)
- **Essential commands**: `chezmoi diff`, `chezmoi apply --dry-run`, `chezmoi apply`

### Claude Code Directory (Managed with exact_)

**Important**: The `.claude` directory is managed via `exact_dot_claude/`:
- **Source**: `~/.local/share/chezmoi/exact_dot_claude/`
- **Target**: `~/.claude` (managed directory)
- **Apply required**: Run `chezmoi apply -v ~/.claude` after making changes
- **Auto-cleanup**: Orphaned skills/commands automatically removed (like Neovim plugins)
- **Runtime protection**: Claude Code runtime directories (`projects/`, `session-env/`, `shell-snapshots/`) are preserved via `.chezmoiignore`

**WARNING**: Do NOT create `.claude/` in the chezmoi source directory (`~/.local/share/chezmoi/.claude/`). This path is:
- Gitignored to prevent confusion
- A runtime directory that may be auto-created by Claude Code
- NOT the managed configuration source

Always use `exact_dot_claude/` for managed Claude Code configuration.

**Benefits of exact_ approach:**
- ✅ Atomic updates prevent race conditions with running Claude processes
- ✅ Automatic removal of deleted/renamed skills and commands
- ✅ Predictable state - target always matches source
- ✅ Explicit checkpoints via `chezmoi apply` ensure stability

**Quick apply alias:**
```bash
alias ca-claude='chezmoi apply -v ~/.claude'
```

### Claude Code Skills & Plugins
This repository includes **Skills** (100+ total) - automatically discovered capabilities that Claude uses based on context:

**⚠️ Skill Activation**: Skills activate based on their YAML `description` field. See `.claude/skills/CLAUDE.md` for best practices on writing high-activation descriptions with specific trigger keywords.

**Core Development Tools:**
- **Chezmoi Expert** - Comprehensive chezmoi guidance (file management, templates, cross-platform configs)
- **Shell Expert** - Shell scripting, CLI tools, automation, and cross-platform scripting
- **fd File Finding** - Fast file search with smart defaults and gitignore awareness
- **rg Code Search** - Blazingly fast code search with ripgrep and regex patterns
- **jq JSON Processing** - JSON querying, filtering, and transformation with jq command-line tool
- **yq YAML Processing** - YAML querying, filtering, and transformation with yq (v4+) command-line tool
- **AST Grep Search** - AST-based code search for structural pattern matching
- **VectorCode Search** - Semantic code search using embeddings for concept-based discovery

**Version Control & Release:**
- **Git Branch PR Workflow** - Branch management, pull request workflows, and GitHub integration
- **Git Commit Workflow** - Commit message conventions, staging, and commit best practices
- **Git Security Checks** - Pre-commit security validation and secret detection
- **Git Repo Detection** - Extract GitHub repository owner/name from git remotes
- **Release-Please Protection** - Prevents manual edits to automated release files (CHANGELOG.md, version fields)

**GitHub Actions Integration:**
- **Claude Code GitHub Workflows** - Workflow design, PR reviews, issue triage, and CI auto-fix
- **GitHub Actions MCP Configuration** - MCP server setup, tool permissions, and multi-server coordination
- **GitHub Actions Auth & Security** - Authentication methods, secrets management, and security best practices
- **GitHub Actions Inspection** - Inspect workflow runs, analyze logs, debug CI/CD failures

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

**MCP Server Management:**
- **MCP Management** - Intelligent MCP server installation and project-based configuration

Skills are located in `.claude/skills/` and managed via chezmoi's `exact_dot_claude/` source directory. Run `chezmoi apply -v ~/.claude` after editing skills.

## Claude Plugins (External Repository)

Plugins have been migrated to a dedicated repository: **[laurigates/claude-plugins](https://github.com/laurigates/claude-plugins)**

This external repository contains **23 Claude Code plugins** organized by domain:

| Category | Plugins |
|----------|---------|
| **Languages** | python-plugin, rust-plugin, typescript-plugin |
| **Infrastructure** | kubernetes-plugin, terraform-plugin, container-plugin |
| **Development** | git-plugin, github-actions-plugin, code-quality-plugin |
| **AI & Agents** | agent-patterns-plugin, graphiti-plugin, blueprint-plugin |
| **Tools** | tools-plugin, testing-plugin, documentation-plugin |
| **Specialized** | dotfiles-plugin, bevy-plugin, accessibility-plugin |

### Installing Plugins

**Interactive (Terminal):**
```bash
# Add the marketplace
claude /plugin marketplace add laurigates/claude-plugins

# Install individual plugins
claude /plugin install git-plugin@lgates-claude-plugins
claude /plugin install python-plugin@lgates-claude-plugins
```

**In GitHub Actions:**
The `claude.yml` workflow automatically installs essential plugins:
- `dotfiles-plugin` - Dotfiles management and chezmoi integration
- `git-plugin` - Git workflows and commit conventions
- `github-actions-plugin` - CI/CD and workflow automation
- `code-quality-plugin` - Code review and quality checks
- `testing-plugin` - Test execution and coverage
- `tools-plugin` - Tool configuration and integration

See `.github/workflows/claude.yml` for the complete workflow configuration.

## MCP Server Management

**Philosophy**: MCP servers are managed **project-by-project** to avoid context bloat.

### Why Project-Scoped?

❌ **Old approach** (user-scoped in `~/.claude/settings.json`):
- Bloated context in every repository
- All MCP tools available everywhere (even when not needed)
- Hidden dependencies not shared with team

✅ **New approach** (project-scoped in `.mcp.json`):
- Clean context - only relevant MCP servers per project
- Explicit project dependencies
- Team-shareable configuration

### MCP Favorites Registry

All your favorite MCP servers are maintained in `.chezmoidata.toml` (disabled by default):

**Available MCP Servers:**
- `github` - GitHub API integration (issues, PRs, repos)
- `vectorcode` - Semantic code search using embeddings
- `playwright` - Browser automation and testing
- `graphiti-memory` - Graph-based memory and knowledge management
- `context7` - Upstash context management
- `consult7` - Consult large context window LLMs via OpenRouter for analyzing extensive codebases
- `pal` - PAL (Provider Abstraction Layer) - Multi-provider LLM integration
- `podio-mcp` - Podio project management integration
- `argocd-mcp` - ArgoCD GitOps deployment management
- `sentry` - Sentry error tracking and monitoring
- `serena` - AI-powered code understanding and refactoring assistant
- `sequential-thinking` - Enhanced reasoning with sequential thinking

### Installing MCP Servers

**Interactive Installation:**
```bash
/configure:mcp  # Claude command for guided installation
```

**Manual Installation:**
Create/edit `.mcp.json` in your project root:
```json
{
  "mcpServers": {
    "github": {
      "command": "go",
      "args": ["run", "github.com/github/github-mcp-server/cmd/github-mcp-server@latest", "stdio"],
      "env": { "GITHUB_TOKEN": "${GITHUB_TOKEN}" }
    },
    "playwright": {
      "command": "bunx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

**Intelligent Suggestions:**
The **MCP Management skill** automatically suggests relevant MCP servers based on:
- Project structure (detects `.github/`, `playwright.config.*`, etc.)
- Required integrations (GitHub, ArgoCD, Sentry, etc.)
- Codebase size (suggests vectorcode for large projects)

### Environment Variables

MCP servers requiring API tokens:
- `github`: Set `GITHUB_TOKEN` in `~/.api_tokens` or project `.env`
- `argocd-mcp`: Set `ARGOCD_SERVER` and `ARGOCD_AUTH_TOKEN`
- `podio-mcp`: Set `PODIO_CLIENT_ID`, `PODIO_CLIENT_SECRET`, etc.

**Never hardcode tokens in `.mcp.json`** - always use environment variable references like `${GITHUB_TOKEN}`.

### Registry Location

Full MCP server configurations: `~/.local/share/chezmoi/.chezmoidata.toml` (section `[mcp_servers]`)

See `.claude/skills/mcp-management/SKILL.md` for complete documentation.

## Linting Commands

### Using mise tasks (recommended):
```bash
mise run lint          # Run all linters (shell, lua, actions, Brewfile)
mise run lint:shell    # Shell scripts only
mise run lint:lua      # Neovim config only
mise run lint:actions  # GitHub Actions only
mise run test          # Run all tests (linting + docker)
```

### Direct commands:
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
- `private_dot_config/mise/config.toml.tmpl` - mise tool version management and tasks
- `private_dot_config/nvim/` - Neovim setup with lazy.nvim
- `private_dot_config/fish/` - Fish shell with cross-platform paths
- `Brewfile` - Homebrew package definitions (bootstrap and system tools)
- `dot_default-*-packages` - Legacy tool package lists (cargo, npm)
- `.chezmoidata.toml` - Data for chezmoi templates (includes uv_tools during migration)

## Detailed Documentation

For detailed information about specific subdirectories, see the following CLAUDE.md files:

### Claude Code Infrastructure
- **`.claude/CLAUDE.md`** - High-level design principles and directory management for Claude Code
- **`.claude/rules/`** - Always-loaded project conventions (delegation, code quality, security, etc.)
- **`.claude/commands/CLAUDE.md`** - Comprehensive guide to slash commands, namespaces, and command creation
- **`.claude/skills/CLAUDE.md`** - Skills system documentation, activation best practices, description writing guide, and external resources

### Configuration & Scripts
- **`private_dot_config/CLAUDE.md`** - Application configuration management with chezmoi naming conventions and cross-platform templating
- **`scripts/CLAUDE.md`** - Maintenance scripts for Claude CLI completions, command migrations, and automation

### Quick Reference

| Topic | Documentation | Key Information |
|-------|---------------|-----------------|
| **Overall guidance** | `CLAUDE.md` (this file) | Repository overview, tools, key files |
| **Claude Code design** | `.claude/CLAUDE.md` | High-level design, directory structure |
| **Project rules** | `.claude/rules/` | Delegation, code quality, security, TDD |
| **Slash commands** | `.claude/commands/CLAUDE.md` | 13 namespaces, command creation guide |
| **Skills catalog** | `.claude/skills/CLAUDE.md` | 100+ skills, activation best practices |
| **Plugins (external)** | [laurigates/claude-plugins](https://github.com/laurigates/claude-plugins) | 23 plugins for Claude Code marketplace |
| **Configuration files** | `private_dot_config/CLAUDE.md` | Chezmoi naming, templates, cross-platform |
| **Maintenance scripts** | `scripts/CLAUDE.md` | CLI completions, command migration |

## Cross-Platform Support

- Templates for platform-specific configurations
- CPU and architecture detection
- The **Chezmoi Expert** Skill provides automatic guidance for template syntax and cross-platform patterns

## Tools

- **just**: Command runner for project-specific tasks
  - Configuration: `justfile` in repository root
  - Run `just` or `just --list` to see available recipes
  - Cross-platform, simple syntax, colored output
- **mise**: Unified tool version management
  - Configuration: `private_dot_config/mise/config.toml.tmpl`
  - Manages: Python, Node, Go, Rust, and CLI tools
  - Backends: `pipx:` (Python tools via uvx), `aqua:` (CLI tools with security checksums)
  - Lockfile: `mise.lock` for reproducible builds
- **Fish**: Primary shell with Starship prompt
- **Neovim**: Editor with LSP, formatting, debugging
- **Homebrew**: Cross-platform package management (bootstrap and system tools)

## CI Pipeline

Multi-platform testing (Ubuntu/macOS) with linting → build stages in `.github/workflows/smoke.yml`

### Claude Code Workflow

The `claude.yml` workflow enables AI-assisted development with:
- Automatic plugin installation from [laurigates/claude-plugins](https://github.com/laurigates/claude-plugins)
- MCP server integration via `.mcp.json`
- Plugin caching for faster CI runs
- Configurable tool permissions via `.github/claude-tools-config.json`

## Security & Release Automation

Security and release-please rules are now in `.claude/rules/`:
- **Security**: See `.claude/rules/security.md` for API token management, secret scanning, and security practices
- **Release-Please**: See `.claude/rules/release-please.md` for protected files and conventional commit workflow

**Quick reference:**
- API tokens in `~/.api_tokens` (not in repo)
- Private files use `private_` prefix
- Never manually edit `CHANGELOG.md` or version fields - use conventional commits
- **detect-secrets** and **TruffleHog** run via pre-commit hooks
