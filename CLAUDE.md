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
This repository includes **Skills** (96 total) - automatically discovered capabilities that Claude uses based on context:

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

This repository also provides **Plugins** - installable packages distributed via the Claude Code marketplace:
- **Dotfiles Toolkit** - 14 specialized agents and 20+ commands for development workflows, code quality, and infrastructure operations

Plugins are located in `plugins/` and can be installed via the marketplace system. See `plugins/README.md` for details.

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
- `zen-mcp-server` - Zen productivity and focus tools
- `podio-mcp` - Podio project management integration
- `argocd-mcp` - ArgoCD GitOps deployment management
- `sentry` - Sentry error tracking and monitoring
- `sequential-thinking` - Enhanced reasoning with sequential thinking

### Installing MCP Servers

**Interactive Installation:**
```bash
/install-mcp  # Claude command for guided installation
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
- **`.claude/CLAUDE.md`** - High-level design principles, delegation strategy, and operational mandates for Claude Code
- **`.claude/commands/CLAUDE.md`** - Comprehensive guide to slash commands, namespaces, and command creation
- **`.claude/skills/CLAUDE.md`** - Skills system documentation: 96 skills by domain, activation best practices, description writing guide, and external resources

### Configuration & Scripts
- **`private_dot_config/CLAUDE.md`** - Application configuration management with chezmoi naming conventions and cross-platform templating
- **`scripts/CLAUDE.md`** - Maintenance scripts for Claude CLI completions, command migrations, and automation

### Quick Reference

| Topic | Documentation | Key Information |
|-------|---------------|-----------------|
| **Overall guidance** | `CLAUDE.md` (this file) | Repository overview, tools, security |
| **Claude Code design** | `.claude/CLAUDE.md` | Delegation strategy, development principles |
| **Slash commands** | `.claude/commands/CLAUDE.md` | 13 namespaces, command creation guide |
| **Skills catalog** | `.claude/skills/CLAUDE.md` | 96 skills, activation best practices, trigger keyword guide |
| **Configuration files** | `private_dot_config/CLAUDE.md` | Chezmoi naming, templates, cross-platform |
| **Maintenance scripts** | `scripts/CLAUDE.md` | CLI completions, command migration |

## Cross-Platform Support

- Templates for platform-specific configurations
- CPU and architecture detection
- The **Chezmoi Expert** Skill provides automatic guidance for template syntax and cross-platform patterns

## Tools

- **mise**: Unified tool version management and task runner
  - Configuration: `private_dot_config/mise/config.toml.tmpl`
  - Manages: Python, Node, Go, Rust, and CLI tools
  - Backends: `pipx:` (Python tools via uvx), `aqua:` (CLI tools with security checksums)
  - Task runner: Replaces Makefile with cross-platform `mise run` tasks
  - Lockfile: `mise.lock` for reproducible builds
- **Fish**: Primary shell with Starship prompt
- **Neovim**: Editor with LSP, formatting, debugging
- **Homebrew**: Cross-platform package management (bootstrap and system tools)

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

## Release-Please Automation

**CRITICAL RULE:** Never manually edit files managed by release-please automation.

### Protected Files

The following files are **automatically managed** by release-please and **must never be manually edited**:

#### Hard Protection (Permission System Blocks)
- `plugins/**/CHANGELOG.md` - Auto-generated from conventional commits
- **Any** `CHANGELOG.md` file across all projects

These files are **blocked** via Claude Code's permission system (`~/.claude/settings.json`). Attempts to edit them will fail with a clear explanation.

#### Soft Protection (Skill Detection & Warning)
- `plugins/**/.claude-plugin/plugin.json` - Version field only
- `.claude-plugin/marketplace.json` - Version references
- `package.json` - Version field in Node.js projects
- `pyproject.toml` - Version field in Python projects
- `Cargo.toml` - Version field in Rust projects

The **release-please-protection skill** (`dot_claude/skills/release-please-protection/`) detects edits to version fields and provides warnings with proper workflow guidance.

### Why This Matters

Manual edits to these files cause:
- 💥 **Merge conflicts** with automated release PRs
- 🔢 **Version inconsistencies** across packages
- 📝 **Duplicate or lost** CHANGELOG entries
- 🚫 **Broken release workflows** requiring manual intervention

### Proper Workflow

Instead of manually editing version or changelog files:

1. **Use conventional commit messages:**
   ```bash
   # For new features (minor version bump)
   git commit -m "feat(auth): add OAuth2 support

   Implements OAuth2 authentication with PKCE.
   Includes refresh token rotation.

   Refs: #42"

   # For bug fixes (patch version bump)
   git commit -m "fix(api): handle timeout edge case

   Fixes race condition in token refresh.

   Fixes: #123"

   # For breaking changes (major version bump)
   git commit -m "feat(api)!: redesign authentication

   BREAKING CHANGE: Auth endpoint now requires OAuth2.
   Migration guide: docs/migration/v2.md"
   ```

2. **Release-please automatically:**
   - Analyzes conventional commits
   - Determines semantic version bump
   - Updates CHANGELOG.md with grouped entries
   - Updates version fields in all manifests
   - Creates a release PR for review

3. **Review and merge the release PR:**
   - Verify version bump is correct
   - Check CHANGELOG entries are accurate
   - Merge to trigger tagged release

### Conventional Commit Types

- `feat:` → Minor version bump (new features)
- `fix:` → Patch version bump (bug fixes)
- `feat!:` or `BREAKING CHANGE:` → Major version bump
- `chore:`, `docs:`, `style:`, `refactor:` → No version bump

### Emergency Override Procedure

If you **absolutely must** manually edit protected files:

```bash
# 1. Temporarily disable protection
vim ~/.claude/settings.json
# Comment out CHANGELOG.md deny rules in permissions.deny

# 2. Make your edits

# 3. Re-enable protection
# Uncomment the deny rules

# 4. Sync with chezmoi if needed
chezmoi apply
```

**Use this only for emergencies** - the automation exists to prevent errors.

### Skill Integration

The **release-please-protection skill** automatically:
- Blocks CHANGELOG.md edits via permission system
- Detects version field modifications before they happen
- Suggests proper conventional commit messages
- Provides workflow guidance and templates
- Explains conflicts when automation fails

See `dot_claude/skills/release-please-protection/` for full documentation:
- `SKILL.md` - Skill behavior and response templates
- `patterns.md` - Protected file patterns reference
- `workflow.md` - Complete release-please workflow guide
