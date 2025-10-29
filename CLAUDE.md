# CLAUDE.md

Chezmoi dotfiles repository with cross-platform development environment configuration.

## Chezmoi Configuration

This repository uses [chezmoi](https://www.chezmoi.io/) for dotfiles management.

### Quick Reference
- **Source directory**: `~/.local/share/chezmoi/` (always edit here)
- **Target locations**: `~/.*` (never edit directly)
- **Essential commands**: `chezmoi diff`, `chezmoi apply --dry-run`, `chezmoi apply`

### Claude Code Skills & Plugins
This repository includes **Skills** (18 total) - automatically discovered capabilities that Claude uses based on context:

**Core Development Tools:**
- **Chezmoi Expert** - Comprehensive chezmoi guidance (file management, templates, cross-platform configs)
- **Shell Expert** - Shell scripting, CLI tools, automation, and cross-platform scripting
- **fd File Finding** - Fast file search with smart defaults and gitignore awareness
- **rg Code Search** - Blazingly fast code search with ripgrep and regex patterns

**Version Control & Release:**
- **Git Workflow** - Preferred git patterns including branching, commits, and validation
- **Release-Please Protection** - Prevents manual edits to automated release files (CHANGELOG.md, version fields)

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

Skills are located in `dot_claude/skills/` (becomes `~/.claude/skills/` after chezmoi apply) and are automatically loaded by Claude when relevant.

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
