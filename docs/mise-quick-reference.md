# mise Quick Reference

A cheat sheet for common mise operations in this dotfiles repository.

## 🚀 Quick Start

```bash
# Apply mise config
chezmoi apply

# Install all tools
mise install

# See available tasks
mise tasks

# Run a task
mise run <task-name>
```

## 📦 Tool Management

### Install Tools

```bash
mise install                          # Install all configured tools
mise install python                   # Install all Python versions
mise install python@3.13              # Install specific version
mise install pipx:ruff                # Install specific pipx tool
mise install aqua:kubernetes/kubernetes  # Install kubectl
```

### Add Tools

```bash
mise use python@3.13                  # Add to config.toml
mise use -g python@3.13               # Add globally (same as above)
mise use pipx:ansible                 # Add Python tool via pipx
mise use aqua:helm/helm               # Add CLI tool via aqua
```

### Update Tools

```bash
mise upgrade                          # Upgrade all tools
mise upgrade python                   # Upgrade all Python versions
mise upgrade pipx:ruff                # Upgrade specific tool
mise outdated                         # Show outdated tools
```

### List & Info

```bash
mise list                             # List all installed tools
mise ls                               # Alias for list
mise current                          # Show currently active versions
mise which python                     # Show which Python is active
mise where python                     # Show installation directory
```

### Remove Tools

```bash
mise uninstall python@3.11            # Uninstall specific version
mise prune                            # Remove unused versions
```

## 🎯 Tasks

### Common Tasks

```bash
# Dotfiles
mise run apply                        # Apply dotfiles to system
mise run status                       # Check dotfiles status
mise run diff                         # Show configuration diff
mise run verify                       # Verify integrity

# Testing & Quality
mise run lint                         # Run all linters
mise run lint:shell                   # Run shellcheck only
mise run lint:lua                     # Run luacheck only
mise run lint:actions                 # Run actionlint only
mise run test                         # Run all tests
mise run qa                           # Quality assurance checks

# Setup
mise run setup                        # Full environment setup
mise run setup:brew                   # Install Homebrew packages
mise run setup:mise                   # Install mise tools
mise run setup:nvim                   # Setup Neovim plugins

# Updates
mise run update                       # Update everything
mise run update:brew                  # Update Homebrew only
mise run update:mise                  # Update mise tools only
mise run update:nvim                  # Update Neovim only
mise run update:uv                    # Update uv tools only

# Utilities
mise run clean                        # Clean caches
mise run security:audit               # Security audit
mise run security:scan                # Scan for secrets
mise run info                         # System information
mise run doctor                       # mise diagnostics
mise run dev                          # Start dev environment
mise run edit                         # Edit dotfiles
```

### Task Management

```bash
mise tasks                            # List all available tasks
mise task info <task-name>            # Show task details
mise task ls                          # Alias for tasks
mise run <task>                       # Run a task
mise watch <task>                     # Run task on file changes
```

## 🔧 Configuration

### View Configuration

```bash
mise config                           # Show active config
mise config ls                        # List all config files
mise ls-remote python                 # Show available Python versions
mise ls-remote pipx:ruff              # Show available tool versions
```

### Trust Config Files

```bash
mise trust                            # Trust .mise.toml in current dir
mise trust --all                      # Trust all config files
```

### Settings

```bash
mise settings                         # Show all settings
mise set experimental true            # Enable experimental features
mise set disable_telemetry true       # Disable telemetry
```

## 🌍 Environment

### View Environment

```bash
mise env                              # Show environment variables
mise env -s fish                      # Show for fish shell
mise env -s zsh                       # Show for zsh shell
mise exec -- env | grep MISE          # See mise-set variables
```

### Run in mise Environment

```bash
mise exec -- python --version         # Run command in mise env
mise x -- python --version            # Alias for exec
mise run <task>                       # Run task (uses mise env)
```

### Shell Activation

```bash
# Fish (in config.fish)
mise activate fish | source

# Zsh (in .zshrc)
eval "$(mise activate zsh)"

# Bash (in .bashrc)
eval "$(mise activate bash)"
```

## 🐛 Diagnostics

### Troubleshooting

```bash
mise doctor                           # Check for issues
mise doctor --verbose                 # Detailed diagnostics
mise current                          # Show active versions
mise which <tool>                     # Find active tool binary
mise where <tool>                     # Show install location
mise cache clear                      # Clear download cache
mise reshim                           # Rebuild shims
```

### Debugging

```bash
MISE_DEBUG=1 mise install python      # Debug installation
MISE_TRACE=1 mise run lint            # Trace execution
mise --log-level debug install        # Debug logging
```

## 📝 Common Patterns

### Per-Project Versions

```bash
# In project directory
cat > .mise.toml << 'EOF'
[tools]
python = "3.11"
node = "20"
EOF

mise install                          # Install project-specific versions
mise trust                            # Trust the config
```

### Pin Exact Versions

```bash
mise use --pin python@3.13.0          # Pin to exact version (no auto-upgrade)
mise use python@3.13                  # Allow patch upgrades (3.13.x)
mise use python@3                     # Allow minor upgrades (3.x.x)
```

### Multiple Versions

```bash
# Install multiple Python versions
mise use python@3.11 python@3.13

# Switch between them
mise use python@3.11                  # Set 3.11 as active
mise use python@3.13                  # Set 3.13 as active

# Use specific version for one command
mise exec python@3.11 -- python script.py
```

## 🔄 Migration Helpers

### From uv to mise

```bash
# Old: uv tool install ruff
mise use pipx:ruff
mise install

# Old: uv tool upgrade --all
mise run update:uv                    # Or just: mise upgrade
```

### From Homebrew to mise

```bash
# Old: brew install kubectl
mise use aqua:kubernetes/kubernetes
mise install

# Old: brew upgrade kubectl
mise upgrade aqua:kubernetes/kubernetes
```

### From Makefile to mise

```bash
# Old: make lint
mise run lint

# Old: make setup
mise run setup

# Old: make update
mise run update
```

## 🎨 Shell Aliases

Add these to your shell config for faster access:

### Fish Shell

```fish
# ~/.config/fish/config.fish
abbr mr 'mise run'
abbr mt 'mise tasks'
abbr mi 'mise install'
abbr mu 'mise upgrade'
abbr ml 'mise list'
abbr mc 'mise current'
abbr md 'mise doctor'
```

### Zsh

```zsh
# ~/.zshrc
alias mr='mise run'
alias mt='mise tasks'
alias mi='mise install'
alias mu='mise upgrade'
alias ml='mise list'
alias mc='mise current'
alias md='mise doctor'
```

## 📊 Task Equivalency Table

| Makefile | mise Command |
|----------|-------------|
| `make apply` | `mise run apply` |
| `make status` | `mise run status` |
| `make diff` | `mise run diff` |
| `make lint` | `mise run lint` |
| `make test` | `mise run test` |
| `make setup` | `mise run setup` |
| `make update` | `mise run update` |
| `make clean` | `mise run clean` |
| `make info` | `mise run info` |
| `make dev` | `mise run dev` |

## 🔑 Key Concepts

- **Tool**: A program or runtime (python, node, kubectl, ruff, etc.)
- **Backend**: Source for tools (pipx, aqua, cargo, npm, etc.)
- **Version**: Specific version of a tool (3.13, latest, stable)
- **Task**: Automated script (replaces Makefile targets)
- **Environment**: Variables and PATH modifications
- **Config**: `.mise.toml` or `config.toml` file with tool definitions
- **Lockfile**: `mise.lock` - pins exact versions for reproducibility

## 🎯 Common Workflows

### Daily Development

```bash
cd ~/dotfiles                         # Enter dotfiles repo
mise run status                       # Check changes
mise run apply                        # Apply changes
mise run lint                         # Lint before commit
```

### Setup New Machine

```bash
cd ~/dotfiles                         # Clone dotfiles
chezmoi apply                         # Apply mise config
mise install                          # Install all tools
mise doctor                           # Verify setup
mise run setup                        # Complete setup
```

### Update Everything

```bash
mise run update                       # Update all tools
# Or separately:
mise run update:brew                  # Update Homebrew
mise run update:mise                  # Update mise tools
mise run update:nvim                  # Update Neovim
```

### Add New Tool

```bash
# Python tool
mise use pipx:black
mise install

# CLI tool
mise use aqua:kubernetes-sigs/kind
mise install

# Runtime
mise use node@22
mise install
```

## 📚 Resources

- **mise Documentation**: https://mise.jdx.dev/
- **Available Tasks**: `mise tasks`
- **Tool Versions**: `mise ls-remote <tool>`
- **aqua Registry**: https://github.com/aquaproj/aqua-registry
- **Migration Guide**: `docs/mise-migration-guide.md`

## 🆘 Get Help

```bash
mise help                             # General help
mise help <command>                   # Command-specific help
mise tasks                            # List available tasks
mise doctor                           # Diagnose issues
```

---

**Pro tip**: Use `mise run` frequently! It's your new `make`. 🚀
