# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository managed by **chezmoi**, designed to create a reproducible development environment across macOS and Linux systems. The repository uses template-driven configuration with platform-specific adaptations.

## Core Architecture

### Chezmoi Structure
- **Template files**: Files ending in `.tmpl` are processed by chezmoi's templating engine
- **Private files**: Prefixed with `private_` to prevent accidental exposure
- **Dot files**: Prefixed with `dot_` become hidden files when applied
- **Run scripts**: `run_*` scripts are executed during chezmoi operations

### Key Components
- **Tool Management**: mise-en-place handles development tool versions
- **Shell**: Fish shell as primary, with cross-platform Homebrew integration
- **Editor**: Neovim with extensive Lua configuration and AI integration
- **Package Management**: Homebrew (cross-platform), pipx (Python), cargo (Rust)

## Essential Commands

### Development Workflow
```bash
# Apply dotfiles changes
chezmoi apply -v

# Check what changes would be made
chezmoi diff

# Verify configuration integrity
chezmoi verify .

# Update all tools and packages
./run_once_update-all.sh
```

### Linting and Testing
```bash
# Run all linters (as used in CI)
shellcheck **/*.sh                    # Shell script linting
luacheck private_dot_config/nvim/lua  # Neovim Lua configuration
actionlint                            # GitHub Actions workflow validation
brew bundle check --file=Brewfile     # Verify Brewfile integrity

# Container testing
docker-compose up                      # Test full environment
```

### Package Management
```bash
# Install/update Homebrew packages
brew bundle install --file=Brewfile

# Update Python tools
pipx upgrade-all

# Install tool versions
mise install
mise upgrade

# Update Neovim plugins and LSP tools
nvim --headless "+Lazy! sync" "+lua require('lazy').load({plugins={'mason.nvim'}})" "+MasonUpdate" +qa
```

## Development Environment

### Tool Versions
- Managed by **mise-en-place** (`.config/mise/config.toml`)
- Automatic activation in directories with `mise.toml` or `.tool-versions`
- Global tools: Python, Node.js, Go, Rust, etc.

### Neovim Configuration
- **Plugin Manager**: lazy.nvim
- **AI Integration**: CodeCompanion with custom prompts and strategies
- **Key Features**: LSP (Mason), formatting (conform.nvim), testing (neotest), debugging (nvim-dap)
- **Custom Setup**: Located in `private_dot_config/nvim/lua/`

### Shell Environment (Fish)
- **Cross-platform**: Adapts to macOS/Linux Homebrew paths
- **Tools**: Starship prompt, Atuin history, vi key bindings
- **Environment**: Optimized for development with EDITOR=nvim, parallel make

## CI/CD Pipeline

### GitHub Actions (`.github/workflows/smoke.yml`)
- **Multi-platform**: Ubuntu and macOS testing
- **Stages**: Lint → Build
- **Linting**: shellcheck, luacheck, actionlint, Brewfile validation
- **Build**: Full chezmoi apply with dependency installation
- **Caching**: Homebrew cache for performance

### Automation Scripts
- **`run_once_update-all.sh`**: Comprehensive update script for tools/packages
- **`run_onchange_*`**: Scripts triggered by configuration changes
- **`run_colors.sh`**: Environment setup script

## Key Directories

### Configuration
- **`private_dot_config/nvim/`**: Complete Neovim setup with 40+ plugins
- **`private_dot_config/fish/`**: Fish shell configuration with platform detection
- **`private_dot_config/git/`**: Git configuration and global ignore patterns

### Package Definitions
- **`dot_default-*-packages`**: Package lists for cargo, npm, pipx
- **`Brewfile`**: Homebrew package definitions with lock file

### Automation
- **`run_*` scripts**: chezmoi hooks for setup and maintenance
- **`.github/workflows/`**: CI pipeline configuration

## Development Practices

### Template System
- Use chezmoi templates for cross-platform compatibility
- Platform detection: `{{ if eq .chezmoi.os "darwin" }}`
- CPU optimization: `{{ .cpu.threads }}` for parallel builds

### Testing Strategy
- Container-based testing with Docker Compose
- Multi-platform CI validation
- Configuration verification with `chezmoi verify`

### AI/LLM Integration
- **CodeCompanion**: Custom Neovim plugin for AI assistance
- **Custom Prompts**: Domain-specific prompts (Arduino, deployment, etc.)
- **Strategies**: Multiple interaction modes and workflows

## Platform-Specific Notes

### macOS
- Homebrew path: `/opt/homebrew/`
- Additional tools: groff, autoconf required for some operations

### Linux (Ubuntu)
- Homebrew path: `/home/linuxbrew/.linuxbrew/`
- Package installation via apt-get for some dependencies

## Important Files to Preserve

When making changes, be careful with:
- **`chezmoi.toml.tmpl`**: Core chezmoi configuration template
- **Template files**: Maintain templating syntax and platform detection
- **Package lists**: `dot_default-*-packages` files define tool installations
- **Run scripts**: Automation hooks that ensure proper setup

## Security Considerations

- API tokens loaded from `~/.api_tokens` (not in repository)
- Private configuration files use `private_` prefix
- No secrets committed to repository
- sudo configurations handled securely with absolute paths
