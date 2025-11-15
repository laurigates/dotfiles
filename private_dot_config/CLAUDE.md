# CLAUDE.md - Configuration Directory

Application configuration files managed by chezmoi with cross-platform support.

## Chezmoi Naming Conventions

This directory uses chezmoi's attribute-based naming system to control file handling:

### Prefix System

| Prefix | Effect | Example | Target |
|--------|--------|---------|--------|
| `dot_` | Add `.` prefix | `dot_gitconfig` | `~/.config/.gitconfig` |
| `private_` | Skip git tracking (local only) | `private_api_keys` | Not committed to repo |
| `executable_` | Make file executable | `executable_startup.sh` | Executable script |
| `symlink_` | Create symlink | `symlink_dot_claude.tmpl` | Symlink to source |
| `readonly_` | Make file read-only | `readonly_config` | Read-only file |

### Combined Prefixes

Multiple prefixes combine their effects:
- `private_dot_config` → `~/.config/` (private, hidden directory)
- `private_executable_script.sh` → Private executable script
- `symlink_dot_claude.tmpl` → Symlink to `~/.claude`

### Template Suffix

Files ending in `.tmpl` are processed as templates:
- Access variables from `chezmoi.toml.tmpl` data section
- Platform-specific logic using Go templates
- Conditional configuration based on OS, architecture, hostname

## Directory Structure

### Editor & Shell

| Directory | Purpose | Key Files |
|-----------|---------|-----------|
| **`nvim/`** | Neovim editor configuration | `init.lua`, `lazy-lock.json`, `lua/plugins/` |
| **`fish/`** | Fish shell configuration | `config.fish`, `functions/`, `completions/` |
| **`private_fish/`** | Private fish shell configs | Sensitive environment variables |

### Version Control & Tools

| Directory | Purpose | Key Files |
|-----------|---------|-----------|
| **`git/`** | Git configuration | `config`, `ignore`, `attributes` |
| **`chezmoi/`** | Chezmoi-specific config | `chezmoi.toml` (merge behavior, template settings) |
| **`mise/`** | Tool version manager | `config.toml` (language runtimes, tools) |

### Terminal & UI

| Directory | Purpose | Key Files |
|-----------|---------|-----------|
| **`private_kitty/`** | Kitty terminal emulator | `kitty.conf`, themes, keybindings |
| **`zellij/`** | Terminal multiplexer | `config.kdl`, layouts |
| **`private_atuin/`** | Shell history manager | `config.toml` (history search, sync) |
| **`ranger/`** | File manager | `rc.conf`, plugins |
| **`rofi/`** | Application launcher | Theme, keybindings |
| **`sketchybar/`** | macOS status bar | Configuration, plugins |

### System & Utilities

| Directory | Purpose | Key Files |
|-----------|---------|-----------|
| **`private_dunst/`** | Notification daemon | `dunstrc` (notification rules) |
| **`private_i3/`** | i3 window manager | `config`, `i3blocks.conf` |
| **`fd/`** | fd file search config | `ignore` patterns |
| **`pet/`** | Snippet manager | Snippet storage |

## Making Changes

### Adding New Configuration

1. **Create file in chezmoi source directory:**
   ```bash
   cd ~/.local/share/chezmoi/private_dot_config
   # For public config:
   mkdir -p newtool
   vim newtool/config.yml

   # For private config (not committed):
   mkdir -p private_newtool
   vim private_newtool/config.yml
   ```

2. **Preview changes:**
   ```bash
   chezmoi diff
   ```

3. **Apply to target:**
   ```bash
   chezmoi apply --dry-run  # Preview
   chezmoi apply            # Actually apply
   ```

### Modifying Existing Configuration

1. **Edit in source directory:**
   ```bash
   cd ~/.local/share/chezmoi/private_dot_config
   vim nvim/init.lua
   ```

2. **Or use chezmoi edit:**
   ```bash
   chezmoi edit ~/.config/nvim/init.lua
   ```

3. **Apply changes:**
   ```bash
   chezmoi apply
   ```

### Using Templates for Cross-Platform Config

Example template for platform-specific paths:

```go-template
# fish/config.fish.tmpl
{{ if eq .chezmoi.os "darwin" -}}
set -gx HOMEBREW_PREFIX /opt/homebrew
{{ else if eq .chezmoi.os "linux" -}}
set -gx HOMEBREW_PREFIX /home/linuxbrew/.linuxbrew
{{ end -}}
```

Template variables available:
- `.chezmoi.os` - Operating system (darwin, linux, windows)
- `.chezmoi.arch` - CPU architecture (amd64, arm64)
- `.chezmoi.hostname` - Machine hostname
- Custom variables from `chezmoi.toml.tmpl` data section

## Testing Configuration Changes

### Local Testing

```bash
# Preview what would change
chezmoi diff

# Dry-run application
chezmoi apply --dry-run --verbose

# Apply to specific file
chezmoi apply ~/.config/nvim/init.lua
```

### Container Testing

```bash
# Test configuration in Docker container
docker-compose run --rm dotfiles-test

# Test specific platform
docker build --platform linux/amd64 -t dotfiles-test .
docker run -it dotfiles-test fish
```

## Tool-Specific Documentation

### Neovim (`nvim/`)

- **Plugin manager:** lazy.nvim
- **LSP setup:** Mason for language servers
- **Key structure:** `init.lua` → `lua/plugins/` → individual plugin configs
- **Modification:** Add new plugins to `lua/plugins/*.lua`, lock with `lazy-lock.json`

### Fish Shell (`fish/`)

- **Functions:** `functions/*.fish` - Auto-loaded on first use
- **Completions:** `completions/*.fish` - Command completions
- **Config:** `config.fish` - Main shell configuration
- **Private config:** `~/.config/private_fish/config.fish` - API keys, tokens

### Git (`git/`)

- **Config:** User settings, aliases, core behavior
- **Ignore:** Global gitignore patterns
- **Attributes:** File handling rules (line endings, diffs)

### mise (`mise/`)

- **Purpose:** Manages language runtimes (Node.js, Python, Ruby, Go) and tools
- **Config:** `config.toml` defines versions per-tool
- **Activation:** Auto-loads correct versions when entering directories

## Troubleshooting

### Configuration not applying

```bash
# Check what chezmoi sees
chezmoi status

# Verify source vs target diff
chezmoi diff

# Re-apply forcefully
chezmoi apply --force
```

### Template errors

```bash
# Execute templates and show output
chezmoi execute-template < private_dot_config/fish/config.fish.tmpl

# Check template data
chezmoi data
```

### Private files appearing in git

Ensure `private_` prefix is used:
```bash
# Rename file to mark as private
mv ~/.local/share/chezmoi/private_dot_config/tool/config \
   ~/.local/share/chezmoi/private_dot_config/private_tool/config
```

## See Also

- **Root CLAUDE.md** - Overall repository guidance
- **Chezmoi Expert Skill** - Automatic guidance for chezmoi operations
- **docs/components.md** - Tool overview and integration points
- **docs/platform_specific.md** - Cross-platform compatibility notes
