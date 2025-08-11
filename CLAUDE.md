# CLAUDE.md

Chezmoi dotfiles repository with cross-platform development environment configuration.

## Structure
- Files ending in `.tmpl` are processed by chezmoi's templating engine
- `private_` prefixed files prevent accidental exposure
- `dot_` prefixed files become hidden when applied
- `run_*` scripts execute during chezmoi operations

## Essential Commands
```bash
chezmoi apply -v                      # Apply changes
chezmoi diff                          # Preview changes
chezmoi verify .                      # Verify integrity
./run_once_update-all.sh              # Update all tools
```

## Linting Commands
```bash
shellcheck **/*.sh                    # Shell scripts
luacheck private_dot_config/nvim/lua  # Neovim config
actionlint                            # GitHub Actions
brew bundle check --file=Brewfile     # Brewfile integrity
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

## CI Pipeline
Multi-platform testing (Ubuntu/macOS) with linting → build stages in `.github/workflows/smoke.yml`

## Security
- API tokens in `~/.api_tokens` (not in repo)
- Private files use `private_` prefix
- No secrets committed
