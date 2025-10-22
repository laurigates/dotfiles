---
name: Dotfiles Management
description: Cross-platform dotfiles management and reproducible development environment setup. Automatically assists with chezmoi templates, tool integration (mise, Fish, Neovim, Homebrew), package management, and platform-specific configurations.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# Dotfiles Management

Expert guidance for creating reproducible, cross-platform development environments using chezmoi and modern tooling.

## Core Capabilities

**Chezmoi Template Design**
- Platform-aware configurations for macOS and Linux
- Go template conditionals with `.chezmoi.*` variables
- File naming conventions: `dot_`, `private_`, `executable_` prefixes
- Cross-platform package management with Homebrew path handling

**Tool Integration**
- **mise**: Development tool version management (`.config/mise/config.toml`)
- **Fish Shell**: Cross-platform shell configuration with Starship prompt
- **Neovim**: Editor setup with LSP, formatting, and debugging
- **Homebrew**: Package management with platform-specific paths

**Security & Privacy**
- Private file handling with `private_` prefix (0600 permissions)
- API tokens stored in `~/.api_tokens` (never in repo)
- Secret scanning with detect-secrets pre-commit hook
- Proper permission management for sensitive configs

## Quick Reference

### Critical Principle
**NEVER edit target files** (`~/.config/`, `~/.bashrc`, etc.)
**ALWAYS edit source** in `~/.local/share/chezmoi/`

### Common Workflows

**Check what will change:**
```bash
chezmoi diff
chezmoi status
```

**Apply changes safely:**
```bash
chezmoi apply --dry-run       # Preview
chezmoi apply -v ~/.config/nvim  # Specific path
chezmoi apply -v              # All changes
```

**Add or update files:**
```bash
chezmoi add ~/.bashrc         # Start managing
chezmoi re-add ~/.bashrc      # Update from target
```

## Platform Detection Templates

### Homebrew Path Handling
```go
{{ if eq .chezmoi.os "darwin" }}
export HOMEBREW_PREFIX="/opt/homebrew"
{{ else if eq .chezmoi.os "linux" }}
export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
{{ end }}
```

### CPU Optimization
```go
{{ if eq .chezmoi.arch "arm64" }}
# Apple Silicon optimizations
export MAKEFLAGS="-j{{ .chezmoi.cpu.logicalCores }}"
{{ else if eq .chezmoi.arch "amd64" }}
# Intel/AMD optimizations
export MAKEFLAGS="-j{{ .chezmoi.cpu.logicalCores }}"
{{ end }}
```

### Hostname-Based Config
```go
{{ if eq .chezmoi.hostname "work-laptop" }}
source ~/.work-config
export GIT_AUTHOR_EMAIL="me@company.com"
{{ else }}
export GIT_AUTHOR_EMAIL="me@personal.com"
{{ end }}
```

## File Organization

### Recommended Structure
```
~/.local/share/chezmoi/
├── dot_config/
│   ├── nvim/              # Neovim configuration
│   ├── fish/              # Fish shell
│   └── mise/              # Tool version management
├── private_dot_ssh/       # SSH configs (private)
├── Brewfile               # Homebrew packages
├── dot_default-*-packages # cargo, npm, uv packages
├── .chezmoi.toml.tmpl     # Main config
├── .chezmoiignore         # Ignored files
└── run_once_*.sh          # Setup scripts
```

## Tool-Specific Guidance

### mise Configuration
```toml
# .config/mise/config.toml
[tools]
node = "lts"
python = "3.12"
rust = "latest"

[env]
_.path = ["~/.local/bin", "$PATH"]
```

### Fish Shell Setup
```fish
# Cross-platform path handling
if test (uname) = Darwin
    set -gx HOMEBREW_PREFIX /opt/homebrew
else
    set -gx HOMEBREW_PREFIX /home/linuxbrew/.linuxbrew
end

fish_add_path $HOMEBREW_PREFIX/bin
```

### Neovim Plugin Management
- Use lazy.nvim for plugin management
- LSP configuration in `lua/plugins/lsp.lua`
- Platform-specific conditionals for clipboard

## Security Practices

**Never Commit:**
- API tokens, keys, credentials
- `.env` files with secrets
- Private SSH keys (use `private_` + encryption)

**Always Use:**
- `private_` prefix for sensitive files (sets 0600)
- `~/.api_tokens` for external API keys
- detect-secrets pre-commit hook
- Encrypted files for SSH keys: `chezmoi add --encrypt`

## Troubleshooting

**Changes not applying:**
```bash
chezmoi managed | grep <file>     # Check if managed
chezmoi apply --force <file>      # Force apply
```

**Template errors:**
```bash
chezmoi data                      # Show available variables
chezmoi execute-template < file   # Test template
chezmoi apply -v --debug <file>   # Debug output
```

**Permission issues:**
```bash
# Use private_ prefix for 0600
mv dot_ssh/config private_dot_ssh/config
```

For advanced operations and detailed examples, see REFERENCE.md.
