---
created: 2025-12-16
modified: 2025-12-16
reviewed: 2025-12-16
name: chezmoi-expert
description: |
  Comprehensive chezmoi dotfiles management expertise including templates, cross-platform
  configuration, file naming conventions, and troubleshooting. Covers source directory
  management, reproducible environment setup, and chezmoi templating with Go templates.
  Use when user mentions chezmoi, dotfiles, cross-platform config, chezmoi apply,
  chezmoi diff, .chezmoidata, or managing configuration files across machines.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# Chezmoi Expert

Expert knowledge for managing dotfiles with chezmoi, including templates, cross-platform support, and best practices.

## Core Expertise

- **Source vs Target Management**: Always work in `~/.local/share/chezmoi/`, never edit target files directly
- **File Naming Conventions**: `dot_`, `private_`, `readonly_`, `executable_`, `exact_`, `symlink_` prefixes
- **Template System**: Go templates with `.chezmoi.*` variables for platform-specific configs
- **Cross-Platform Support**: Conditional logic for macOS/Linux differences

## Critical Workflow

**ALWAYS follow this workflow:**
1. `chezmoi diff` - Preview changes before applying
2. `chezmoi apply --dry-run` - Safe testing
3. `chezmoi apply -v <path>` - Apply specific paths first
4. Let user review before full `chezmoi apply`

## Finding the Source File — Don't Translate Prefixes by Hand

When you know a **target** path and need the **source**, ask chezmoi instead
of mentally translating `dot_`/`private_`/`exact_`/`.tmpl`/`encrypted_`.
Stacked prefixes make manual guessing error-prone, and a wrong guess points
at a nonexistent path.

```bash
chezmoi source-path ~/.zshrc                 # → .../dot_zshrc.tmpl
chezmoi source-path ~/.config/mise/config.toml  # → .../private_dot_config/mise/config.toml.tmpl
chezmoi target-path <source-file>            # inverse: source → target
```

Canonical edit loop: **`chezmoi source-path <target>` → `Read` it → `Edit`
it → `chezmoi apply`**. `source-path` exits non-zero when the target is not
managed — check the exit code; if it errors, use `chezmoi unmanaged <path>`
or `chezmoi managed <path>` to confirm whether the file is unmanaged vs.
ignored (`chezmoi ignored`).

## Essential Commands

```bash
# Find the source / target for a path (let chezmoi compute prefixes)
chezmoi source-path ~/.zshrc    # Target → source (exits non-zero if unmanaged)
chezmoi target-path <src-file>  # Source → target (inverse)
chezmoi unmanaged ~/.config     # Home-dir files NOT managed by chezmoi

# Check differences
chezmoi diff                    # All pending changes
chezmoi status                  # Quick status overview
chezmoi diff ~/.config/nvim     # Specific path changes

# Apply changes
chezmoi apply --dry-run         # Safe preview
chezmoi apply -v ~/.config/nvim # Apply specific path
chezmoi apply -v                # Apply all after review

# Manage files
chezmoi add ~/.bashrc           # Start managing file
chezmoi re-add ~/.bashrc        # Update from modified target
chezmoi managed                 # List managed files
chezmoi verify                  # Verify target matches source (exit 0 = clean)

# Templates
chezmoi data                    # Show template variables
chezmoi cat ~/.config/file      # Preview rendered target content (renders .tmpl, decrypts)
chezmoi execute-template < file # Test template
```

## File Naming Reference

```
Source                           → Target
dot_bashrc                      → ~/.bashrc
private_dot_ssh/config          → ~/.ssh/config (mode 0600)
dot_config/nvim/init.lua.tmpl   → ~/.config/nvim/init.lua (templated)
exact_dot_config/app/           → ~/.config/app/ (exact match)
executable_script.sh            → ~/script.sh (mode 0755)
```

## Template Examples

### Platform Detection
```go
{{ if eq .chezmoi.os "darwin" }}
# macOS specific
export HOMEBREW_PREFIX="/opt/homebrew"
{{ else if eq .chezmoi.os "linux" }}
# Linux specific
export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
{{ end }}
```

### Architecture-Specific
```go
{{ if eq .chezmoi.arch "arm64" }}
# Apple Silicon
export DOCKER_DEFAULT_PLATFORM=linux/arm64/v8
{{ else if eq .chezmoi.arch "amd64" }}
# Intel/AMD
export DOCKER_DEFAULT_PLATFORM=linux/amd64
{{ end }}
```

## Special Files

- `.chezmoi.toml.tmpl` - Main configuration template
- `.chezmoiignore` - Files to ignore
- `.chezmoiremove` - Files to remove from target
- `.chezmoiexternal.toml` - External file management
- `run_once_*.sh` - Run once on first apply
- `run_onchange_*.sh` - Run when hash changes

## Troubleshooting

### Changes Not Applying
```bash
chezmoi managed | grep filename  # Check if managed
chezmoi apply --force ~/.config/file  # Force apply
```

### Template Errors
```bash
chezmoi execute-template < file.tmpl  # Test rendering
chezmoi data                          # Check variables
chezmoi apply -v --debug ~/.config/file  # Debug output
```

### Merge Conflicts
```bash
chezmoi merge ~/.config/file     # Three-way merge
chezmoi source-path ~/.config/file  # Get source path for manual edit
```

For detailed reference documentation, see REFERENCE.md.
