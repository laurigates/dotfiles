# CLAUDE.md

Chezmoi dotfiles repository with cross-platform development environment configuration.

## Structure
- Files ending in `.tmpl` are processed by chezmoi's templating engine
- `private_` prefixed files prevent accidental exposure
- `dot_` prefixed files become hidden when applied
- `run_*` scripts execute during chezmoi operations

## Essential Commands
```bash
chezmoi diff                          # ALWAYS preview changes before applying
chezmoi apply -v                      # Apply changes (after reviewing diff)
chezmoi verify .                      # Verify integrity
./run_once_update-all.sh              # Update all tools
```

### Chezmoi Best Practices
- **ALWAYS run `chezmoi diff` before `chezmoi apply`** to review what will change
- Use `chezmoi diff | head -50` for quick preview of large changesets
- When making changes in the chezmoi source directory, verify with diff before applying

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

### Implementation Guidelines
- **Verify syntax and parameters** in official documentation before coding
- **Check for breaking changes** and version compatibility requirements
- **Review best practices** and recommended patterns in the tool's documentation
- **Validate configuration options** against current documentation versions

### Critical Documentation Sources
- Tool-specific documentation (mise, Fish, Neovim, Homebrew, chezmoi)
- GitHub Actions documentation for workflow modifications
- Platform-specific guides for cross-platform compatibility
- Security documentation for secrets handling and API token management

### Before Any Implementation
1. Read relevant documentation sections thoroughly
2. Verify syntax and available options
3. Check for deprecated features or breaking changes
4. Confirm implementation details match current best practices

## CI Pipeline
Multi-platform testing (Ubuntu/macOS) with linting → build stages in `.github/workflows/smoke.yml`

## Security
- API tokens in `~/.api_tokens` (not in repo)
- Private files use `private_` prefix
- No secrets committed
- **detect-secrets** pre-commit hook prevents accidental secret commits
- **TruffleHog** scans for leaked credentials in git history
- Both tools run automatically on commit via pre-commit hooks
