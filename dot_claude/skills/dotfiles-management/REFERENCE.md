# Dotfiles Management Reference

Detailed reference for cross-platform development environment configuration and tool integration.

## Repository Structure

This dotfiles repository uses chezmoi for cross-platform management with the following key components:

### Configuration Files
- `private_dot_config/nvim/` - Neovim setup with lazy.nvim
- `private_dot_config/fish/` - Fish shell with cross-platform paths
- `private_dot_config/mise/config.toml` - Tool version management
- `Brewfile` - Homebrew package definitions
- `dot_default-*-packages` - Tool package lists (cargo, npm, uv)

### Special Files
- `dot_claude/` - Claude Code configuration and agents
- `private_dot_ssh/` - SSH configuration (private)
- `dot_api_tokens.tmpl` - API token template (references external file)

## Linting and Quality Checks

### Available Linting Commands
```bash
# Shell scripts
shellcheck **/*.sh

# Neovim Lua configuration
luacheck private_dot_config/nvim/lua

# GitHub Actions workflows
actionlint

# Brewfile integrity
brew bundle check --file=Brewfile

# Run all pre-commit hooks
pre-commit run --all-files
```

### Secret Scanning
```bash
# Scan for new secrets
detect-secrets scan --baseline .secrets.baseline

# Review flagged secrets
detect-secrets audit .secrets.baseline

# Run via pre-commit
pre-commit run detect-secrets --all-files
```

## Cross-Platform Tool Configuration

### Homebrew Path Detection

Different paths on different platforms:
- **macOS ARM64**: `/opt/homebrew/`
- **macOS Intel**: `/usr/local/`
- **Linux**: `/home/linuxbrew/.linuxbrew/`

Template pattern:
```go
{{- if eq .chezmoi.os "darwin" -}}
{{-   if eq .chezmoi.arch "arm64" -}}
HOMEBREW_PREFIX="/opt/homebrew"
{{-   else -}}
HOMEBREW_PREFIX="/usr/local"
{{-   end -}}
{{- else -}}
HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
{{- end -}}
```

### mise (Tool Version Management)

Configuration in `.config/mise/config.toml`:

```toml
[tools]
# Use "latest", "lts", or specific versions
node = "lts"
python = "3.12"
go = "1.22"
rust = "latest"

[env]
# Environment modifications
_.path = ["~/.local/bin", "$PATH"]
_.file = ".env"

[settings]
experimental = true
```

Automatic activation in Fish:
```fish
# In config.fish
mise activate fish | source
```

### Fish Shell Configuration

Cross-platform path handling:
```fish
# Platform detection
switch (uname)
    case Darwin
        set -gx HOMEBREW_PREFIX /opt/homebrew
    case Linux
        set -gx HOMEBREW_PREFIX /home/linuxbrew/.linuxbrew
end

# Add to path
fish_add_path $HOMEBREW_PREFIX/bin
fish_add_path ~/.local/bin
```

Integration with tools:
```fish
# Starship prompt
starship init fish | source

# Atuin history
atuin init fish | source

# mise activation
mise activate fish | source

# Vi key bindings
fish_vi_key_bindings
```

## Neovim Configuration

### Plugin Management with lazy.nvim

Structure:
```
private_dot_config/nvim/
├── init.lua              # Entry point
├── lua/
│   ├── config/          # Core configuration
│   │   ├── options.lua
│   │   ├── keymaps.lua
│   │   └── autocmds.lua
│   └── plugins/         # Plugin specifications
│       ├── lsp.lua
│       ├── completion.lua
│       ├── treesitter.lua
│       └── ui.lua
```

### LSP Configuration

Platform-specific LSP servers in templates:
```lua
-- lua/plugins/lsp.lua.tmpl
local servers = {
  'lua_ls',
  'pyright',
  'ts_ls',
{{ if eq .chezmoi.os "darwin" }}
  'sourcekit',  -- Swift LSP on macOS
{{ end }}
}
```

### Cross-Platform Clipboard

```lua
-- Platform-specific clipboard
if vim.fn.has('macunix') == 1 then
  vim.g.clipboard = {
    name = 'macOS-clipboard',
    copy = { ['+'] = 'pbcopy', ['*'] = 'pbcopy' },
    paste = { ['+'] = 'pbpaste', ['*'] = 'pbpaste' }
  }
elseif vim.fn.has('unix') == 1 then
  vim.g.clipboard = {
    name = 'xclip',
    copy = { ['+'] = 'xclip -selection clipboard', ['*'] = 'xclip' },
    paste = { ['+'] = 'xclip -selection clipboard -o', ['*'] = 'xclip -o' }
  }
end
```

## Package Management

### Brewfile Organization

```ruby
# Core tools
brew "chezmoi"
brew "git"
brew "mise"
brew "fish"
brew "starship"
brew "neovim"

# Development tools
brew "gh"          # GitHub CLI
brew "pre-commit"
brew "shellcheck"
brew "actionlint"

# Modern replacements
brew "ripgrep"     # Better grep
brew "fd"          # Better find
brew "bat"         # Better cat
brew "eza"         # Better ls

# Platform-specific
if OS.mac?
  cask "visual-studio-code"
  cask "alacritty"
end
```

### Package List Files

**cargo packages** (`dot_default-cargo-packages`):
```
ripgrep
fd-find
bat
eza
tokei
cargo-update
```

**npm packages** (`dot_default-npm-packages`):
```
typescript
prettier
eslint
@biomejs/biome
```

**uv tools** (`dot_default-uv-tools`):
```
ruff
black
mypy
pytest
```

## Security and Privacy

### API Token Management

External file approach:
```bash
# ~/.api_tokens (not in repo)
export GITHUB_TOKEN="ghp_xxxxx"  # pragma: allowlist secret
export OPENAI_API_KEY="sk-xxxxx"  # pragma: allowlist secret
```

Referenced in templates:
```bash
# dot_bashrc.tmpl
{{ if stat "~/.api_tokens" }}
source ~/.api_tokens
{{ end }}
```

### Private File Permissions

Automatic with prefixes:
- `private_` → 0600 (user read/write only)
- `private_executable_` → 0700 (user rwx only)
- `readonly_` → 0444 (read-only)

Example:
```
private_dot_ssh/config              → ~/.ssh/config (0600)
private_dot_ssh/private_id_rsa      → ~/.ssh/id_rsa (0600)
private_executable_dot_local/bin/secret.sh → ~/.local/bin/secret.sh (0700)
```

### Encrypted Files

For highly sensitive data:
```bash
# Configure GPG encryption
chezmoi edit-config

# Add to config
[encryption]
  recipient = "your-gpg-key-id"

# Add encrypted file
chezmoi add --encrypt ~/.ssh/id_rsa

# Results in source:
encrypted_private_dot_ssh/private_id_rsa.asc
```

## CI/CD Integration

### GitHub Actions Pipeline

Multi-platform testing (`.github/workflows/smoke.yml`):
```yaml
name: Smoke Test
on: [push, pull_request]

jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v4

      - name: Install chezmoi
        run: sh -c "$(curl -fsLS get.chezmoi.io)"

      - name: Lint shell scripts
        run: shellcheck **/*.sh

      - name: Lint Lua
        run: luacheck private_dot_config/nvim/lua

      - name: Check Brewfile
        run: brew bundle check --file=Brewfile

      - name: Validate chezmoi
        run: |
          chezmoi init --source .
          chezmoi verify
          chezmoi apply --dry-run
```

## Bootstrap and Setup

### New Machine Setup

```bash
#!/bin/bash
# Bootstrap script for new machine

# Install Homebrew (if needed)
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install chezmoi
brew install chezmoi

# Initialize from repo
chezmoi init --apply https://github.com/username/dotfiles.git

# Install Homebrew packages
brew bundle --global

# Install mise
curl https://mise.run | sh
mise install

# Set Fish as default shell
chsh -s $(which fish)
```

### Update Workflow

```bash
# Update dotfiles
chezmoi update

# Update Homebrew packages
brew bundle --global --cleanup

# Update mise tools
mise upgrade

# Update Fish plugins
fisher update

# Update Neovim plugins
nvim --headless "+Lazy! sync" +qa
```

## Troubleshooting Common Issues

### Issue: Homebrew not found after chezmoi apply

**Cause:** PATH not set correctly for platform

**Solution:** Check template in `dot_config/fish/config.fish.tmpl`:
```fish
{{ if eq .chezmoi.os "darwin" }}
eval "$(/opt/homebrew/bin/brew shellenv)"
{{ else }}
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
{{ end }}
```

### Issue: mise not activating tools

**Cause:** mise not initialized in shell

**Solution:** Add to Fish config:
```fish
mise activate fish | source
```

### Issue: Neovim LSP not working

**Cause:** LSP servers not installed

**Solution:** Install via Mason:
```vim
:Mason
:MasonInstall <server-name>
```

Or use mise:
```toml
# In .config/mise/config.toml
[tools]
"npm:typescript-language-server" = "latest"
"npm:pyright" = "latest"
```

### Issue: Git commits blocked by pre-commit

**Cause:** Pre-commit hooks failing

**Solution:**
```bash
# Run hooks manually to see errors
pre-commit run --all-files

# Update hooks
pre-commit autoupdate

# Skip hooks (use sparingly)
git commit --no-verify
```

## Advanced Patterns

### Conditional File Inclusion

```
# .chezmoiignore
{{ if ne .chezmoi.os "darwin" }}
.config/karabiner
.config/hammerspoon
{{ end }}

{{ if ne .chezmoi.os "linux" }}
.config/i3
.config/sway
{{ end }}
```

### Dynamic Package Lists

```toml
# .chezmoi.toml.tmpl
[data]
{{ if eq .chezmoi.os "darwin" }}
  [data.packages]
    brew_casks = ["alacritty", "visual-studio-code"]
{{ end }}
```

### Machine-Specific Overrides

```toml
# ~/.config/chezmoi/chezmoi.toml (not in repo)
[data]
  machine_type = "work"
  git_email = "work@company.com"
```

Reference in templates:
```git
# dot_gitconfig.tmpl
[user]
  email = {{ .git_email | default "personal@email.com" }}
```
