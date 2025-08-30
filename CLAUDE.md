# CLAUDE.md

Chezmoi dotfiles repository with cross-platform development environment configuration.

## Structure

- Files ending in `.tmpl` are processed by chezmoi's templating engine
- `private_` prefixed files prevent accidental exposure
- `dot_` prefixed files become hidden when applied
- `run_*` scripts execute during chezmoi operations

## Essential Commands

```bash
# Checking differences
chezmoi diff                          # Shows changes between source and target (ALL files)
chezmoi diff ~/.config/nvim           # Shows changes for a specific TARGET path
chezmoi diff --reverse                # Shows what would be REMOVED from source

# Applying changes
chezmoi apply --dry-run               # Test what would be applied (safer than direct apply)
chezmoi apply -v ~/.config/nvim       # Apply changes to specific TARGET path
chezmoi apply -v                      # Apply all changes (only after user reviews and approves)

# Other commands
chezmoi verify .                      # Verify integrity
./run_once_update-all.sh              # Update all tools
```

### Chezmoi Best Practices

- **ALWAYS run `chezmoi diff` before any apply operation** to review what will change
- **Use TARGET paths with `chezmoi diff`** - e.g., `chezmoi diff ~/.claude/hooks/` to see changes for that directory
- **Use `chezmoi apply --dry-run`** to safely test changes without actually applying them
- **Never run `chezmoi apply` directly** - let the user decide when to apply after reviewing
- Use `chezmoi diff | head -50` for quick preview of large changesets
- When making changes in the chezmoi source directory, verify with diff before applying
- Always make changes to files in the chezmoi managed directory instead of modifying target files

### Important Note on Paths

- **Source paths**: Files in the chezmoi directory (e.g., `/Users/lgates/.local/share/chezmoi/dot_claude/`)
- **Target paths**: Where files are applied (e.g., `~/.claude/`)
- `chezmoi diff` and `chezmoi apply` expect **TARGET paths**, not source paths

### Working with Chezmoi Files

- **ALWAYS work with chezmoi source files** in `~/.local/share/chezmoi/` when making changes
- **Never edit target files directly** (e.g., don't edit `~/.claude/hooks/`, edit `~/.local/share/chezmoi/dot_claude/hooks/`)
- **Use `chezmoi diff` to verify changes** before they are applied to the target
- **Source files are the single source of truth** - all modifications should be made there

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

- `chezmoi.toml.tmpl` - Core chezmoi configuration template
- `private_dot_config/nvim/` - Neovim setup with lazy.nvim
- `private_dot_config/fish/` - Fish shell with cross-platform paths
- `Brewfile` - Homebrew package definitions
- `dot_default-*-packages` - Tool package lists (cargo, npm, pipx)

## Templates

- Platform detection: `{{ if eq .chezmoi.os "darwin" }}`
- CPU optimization: `{{ .cpu.threads }}`
- Use templates for cross-platform compatibility

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
