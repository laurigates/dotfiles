# Mise Migration Guide

This guide helps you migrate from the current Homebrew + uv + Makefile setup to a mise-based unified tooling configuration.

## 📋 What Was Created

### 1. **`private_dot_config/mise/config.toml.tmpl`**

A comprehensive mise configuration that includes:

- **Runtime Versions**: Python (3.11, 3.13), Node (22), Bun, Go (1.23), Rust (stable)
- **Python Tools**: All 18 tools from `.chezmoidata.toml` via `pipx:` backend (automatically uses uvx!)
- **CLI Tools**: Kubernetes, Terraform, search tools via `aqua:` backend (security-focused)
- **Environment Variables**: Editor settings, XDG directories, API token loading
- **Tasks**: Complete replacement for all Makefile targets
- **Settings**: Aggressive activation, legacy version file support, telemetry disabled
- **Hooks**: Optional security and cleanup automation (commented out)

## 🚀 Quick Start

### Step 1: Apply the Configuration

```bash
# Apply mise config via chezmoi
chezmoi apply

# Verify mise can read the config
mise doctor

# See what tools would be installed
mise list
```

### Step 2: Install Tools

```bash
# Install ALL tools defined in config.toml
mise install

# Or install specific categories
mise install python@3.13
mise install pipx:ruff
mise install aqua:kubernetes/kubernetes
```

### Step 3: Start Using Tasks

```bash
# See all available tasks
mise tasks

# Run a task (replaces `make <target>`)
mise run lint
mise run update
mise run setup
```

## 📊 Command Equivalency Reference

### Makefile → mise Tasks

| Makefile Command | mise Command | Description |
|-----------------|-------------|-------------|
| `make apply` | `mise run apply` | Apply dotfiles configuration |
| `make status` | `mise run status` | Check dotfiles status |
| `make diff` | `mise run diff` | Show configuration differences |
| `make verify` | `mise run verify` | Verify configuration integrity |
| `make check` | `mise run check` | Alias for status |
| `make lint` | `mise run lint` | Run all linters |
| `make lint` (shell only) | `mise run lint:shell` | Run shellcheck only |
| `make lint` (lua only) | `mise run lint:lua` | Run luacheck only |
| `make lint` (actions only) | `mise run lint:actions` | Run actionlint only |
| `make test` | `mise run test` | Run all tests |
| `make docker` | `mise run docker` | Test with Docker Compose |
| `make qa` | `mise run qa` | Quality assurance checks |
| `make setup` | `mise run setup` | Complete environment setup |
| `make setup-brew` | `mise run setup:brew` | Install Homebrew packages |
| `make setup-mise` | `mise run setup:mise` | Install mise tools |
| `make setup-nvim` | `mise run setup:nvim` | Setup Neovim plugins |
| `make update` | `mise run update` | Update all tools |
| `make update` (brew only) | `mise run update:brew` | Update Homebrew only |
| `make update` (mise only) | `mise run update:mise` | Update mise tools only |
| `make update` (nvim only) | `mise run update:nvim` | Update Neovim only |
| `make update` (uv only) | `mise run update:uv` | Update uv tools only |
| `make clean` | `mise run clean` | Clean up caches |
| `make security-audit` | `mise run security:audit` | Run security audit |
| - | `mise run security:scan` | Run detect-secrets scan |
| `make dev` | `mise run dev` | Start development environment |
| `make edit` | `mise run edit` | Edit dotfiles |
| `make info` | `mise run info` | Show system information |
| - | `mise run doctor` | Run mise diagnostics |
| `make ci` | `mise run ci` | Run CI checks locally |
| `make docs` | `mise run docs` | Show documentation info |

### Tool Installation

| Current Method | mise Method | Notes |
|---------------|------------|-------|
| `brew install python@3.13` | `mise use python@3.13` | Runtime version management |
| `uv tool install ruff` | `mise use pipx:ruff` | Automatically uses uvx |
| `brew install kubectl` | `mise use aqua:kubernetes/kubernetes` | Security features + checksums |
| `cargo install bat` | `mise use aqua:sharkdp/bat` | Pre-built binaries (faster) |
| `npm install -g typescript` | `mise use npm:typescript` | Node tools |

### Tool Updates

| Current Method | mise Method |
|---------------|------------|
| `brew upgrade` | `mise upgrade` (or `mise run update:mise`) |
| `uv tool upgrade --all` | `mise upgrade` (if tools migrated to pipx: backend) |
| `cargo install bat --force` | `mise upgrade` |

## 🔄 Migration Strategy

### Phase 1: Test Without Breaking Current Setup (30 minutes)

1. **Apply mise config:**
   ```bash
   chezmoi apply
   ```

2. **Install a few test tools:**
   ```bash
   # Test Python runtime
   mise use python@3.13
   mise install

   # Test pipx backend with uvx
   mise use pipx:ruff
   mise install

   # Verify it works
   python --version
   ruff --version
   ```

3. **Test a few tasks:**
   ```bash
   mise run info
   mise run lint:shell
   mise run status
   ```

4. **Keep your current tools** - mise and Homebrew/uv coexist peacefully

### Phase 2: Migrate Python Tools (1-2 hours)

1. **Install all Python tools via mise:**
   ```bash
   mise install "pipx:*"
   ```

2. **Verify they work:**
   ```bash
   mise exec -- ruff --version
   mise exec -- ansible --version
   mise exec -- pre-commit --version
   ```

3. **Update shell PATH** (mise handles this via shell activation)

4. **(Optional) Remove uv tools:**
   ```bash
   # Only after confirming mise versions work!
   uv tool list
   uv tool uninstall ruff ansible pre-commit ...
   ```

### Phase 3: Migrate CLI Tools (2-3 hours)

1. **Install aqua-backed tools:**
   ```bash
   mise install "aqua:*"
   ```

2. **Test critical tools:**
   ```bash
   mise exec -- kubectl version
   mise exec -- helm version
   mise exec -- rg --version
   ```

3. **(Optional) Remove Homebrew formulae:**
   ```bash
   # Only for tools successfully migrated to mise
   brew uninstall kubectl helm ripgrep fd bat
   ```

4. **Keep in Homebrew:**
   - System-level: chezmoi, git, curl, fish, uv
   - GUI apps: All casks (Ghostty, Obsidian, VS Code, etc.)
   - Services: postgresql, mosquitto
   - Platform-specific: lldpd, mas

### Phase 4: Adopt mise Tasks (30 minutes)

1. **Update your muscle memory:**
   ```bash
   # Old way
   make lint

   # New way
   mise run lint

   # Even shorter (with mise shell alias)
   alias mr='mise run'
   mr lint
   ```

2. **Add shell aliases** to your fish config:
   ```fish
   # ~/.config/fish/config.fish
   abbr mr 'mise run'
   abbr mt 'mise tasks'
   abbr mi 'mise install'
   abbr mu 'mise upgrade'
   ```

3. **Update CI/CD** (already using `setup-mise@v0`, no changes needed!)

4. **(Optional) Deprecate Makefile:**
   - Keep for backwards compatibility
   - Or replace with simple wrapper: `make %: ; mise run $@`

## 🎯 Benefits You'll Gain

### 1. **Unified Tool Management**

**Before:**
```bash
brew install python@3.13          # Runtime
uv tool install ruff              # Python tool
cargo install bat                 # Rust tool
npm install -g typescript         # Node tool
# 4 different package managers!
```

**After:**
```bash
mise install                      # Everything!
# 1 command, 1 lockfile
```

### 2. **Automatic Version Switching**

**Before:**
```bash
cd ~/project-a                    # Uses system Python 3.13
cd ~/project-b                    # Still uses 3.13 (oops!)
```

**After:**
```bash
cd ~/project-a                    # Sees .mise.toml, switches to Python 3.11
cd ~/project-b                    # Sees .mise.toml, switches to Python 3.13
# Automatic, seamless
```

### 3. **Reproducible Environments**

**Before:**
```bash
# No lockfile for tool versions
brew install kubectl              # Gets latest (1.30?)
# Teammate installs later
brew install kubectl              # Gets newer version (1.31?)
# CI uses different version (1.29?)
# "Works on my machine" syndrome
```

**After:**
```bash
mise install                      # Reads mise.lock
# Everyone gets EXACT same versions
# CI, teammates, future you - all identical
```

### 4. **Better Performance**

**Before:**
```bash
uv tool install ruff              # 2 seconds
cargo install bat                 # 5 minutes (compiles from source)
```

**After:**
```bash
mise install pipx:ruff            # Uses uvx: 0.5 seconds!
mise install aqua:sharkdp/bat     # Pre-built binary: 3 seconds
```

### 5. **Enhanced Security**

**Before:**
```bash
brew install kubectl              # SHA256 checksum only
```

**After:**
```bash
mise install aqua:kubernetes/kubernetes
# SHA256 + GitHub Attestations + SLSA Provenance + Cosign signatures
```

### 6. **Cross-Platform Task Runner**

**Before:**
```bash
# Makefile uses bash-specific syntax
# Doesn't work well on Windows
# Tabs vs spaces issues
```

**After:**
```bash
# mise tasks work on macOS, Linux, Windows
# Consistent syntax (TOML)
# Dependency management built-in
```

## 🔧 Customization Examples

### Per-Project Version Overrides

```bash
# In a specific project directory
cd ~/my-old-project
echo 'python = "3.11"' > .mise.toml

cd ~/my-new-project
echo 'python = "3.13"' > .mise.toml

# mise automatically switches versions when you cd
```

### Custom Tasks for Your Projects

```toml
# ~/my-project/.mise.toml
[tasks.deploy]
description = "Deploy to production"
run = """
  mise run lint
  mise run test
  ./scripts/deploy.sh
"""

[tasks.watch]
description = "Watch and reload on file changes"
run = "mise watch -- npm run dev"
```

### Environment Variables Per Project

```toml
# ~/my-project/.mise.toml
[env]
DATABASE_URL = "postgresql://localhost/myproject"
DEBUG = "true"
API_KEY = "{{ env.MY_SECRET_KEY }}"
```

## 🐛 Troubleshooting

### Issue: `mise: command not found`

**Solution:**
```bash
# Ensure mise is activated in your shell
# Already configured in dot_zshrc.tmpl:161 and config.fish.tmpl:49

# For zsh:
eval "$(mise activate zsh)"

# For fish:
mise activate fish | source

# Or re-apply dotfiles:
chezmoi apply
```

### Issue: Tools not in PATH

**Solution:**
```bash
# mise needs to be activated (see above)
# Or use mise exec:
mise exec -- ruff --version

# Or add to shell config:
mise reshim
```

### Issue: `uvx` not being used

**Solution:**
```bash
# Check if uv is installed
which uv

# Force uvx for specific tool:
mise use "pipx:ruff" --option uvx=true

# Disable uvx for problematic tool:
mise use "pipx:problem-tool" --option uvx=false
```

### Issue: Wrong Python version active

**Solution:**
```bash
# Check what mise sees:
mise current

# Check for .tool-versions or .mise.toml in parent directories
mise ls

# Force global version:
mise use -g python@3.13
```

### Issue: Slow installs from aqua

**Solution:**
```bash
# aqua backend is already fast (pre-built binaries)
# If slow, check network connection or switch to cargo:
mise use cargo:bat  # Compiles from source, slower but works offline
```

## 📚 Additional Resources

- **mise Documentation**: https://mise.jdx.dev/
- **aqua Registry**: https://github.com/aquaproj/aqua-registry
- **mise Tasks Reference**: https://mise.jdx.dev/tasks/
- **mise Backends**: https://mise.jdx.dev/dev-tools/backends/

## 🎓 Learning mise Commands

### Essential Commands

```bash
# See what's configured
mise list                    # List all tools and versions

# Install tools
mise install                 # Install everything
mise install python@3.13     # Install specific tool

# Manage versions
mise use python@3.13         # Set version globally
mise use -g python@3.13      # Explicitly global
mise use --pin python@3.13   # Pin exact version (no upgrades)

# Tasks
mise tasks                   # List all tasks
mise run <task>              # Run a task
mise watch <task>            # Run task on file changes

# Updates
mise upgrade                 # Upgrade all tools to latest
mise outdated                # Show outdated tools

# Diagnostics
mise doctor                  # Check for issues
mise current                 # Show active versions
mise which python            # Show which Python is active

# Cleanup
mise prune                   # Remove unused versions
mise cache clear             # Clear download cache
```

### Power User Tips

```bash
# Install multiple tools at once
mise install python@3.13 node@22 rust@stable

# Run command in mise environment without activating
mise exec -- python --version

# Generate shell completions (already in .chezmoidata.toml)
mise completion zsh > ~/.zsh/completions/_mise

# Export environment variables to eval
mise env -s fish             # For fish shell
mise env -s zsh              # For zsh

# See what mise would set
mise env

# Trust a config file (security feature)
mise trust                   # In directory with .mise.toml
```

## 🔐 Security Considerations

1. **Trust Config Files**: mise will prompt you to trust `.mise.toml` files from untrusted sources
   ```bash
   mise trust                # Trust current directory's config
   ```

2. **API Tokens**: Already configured to load from `~/.api_tokens` (gitignored)

3. **aqua Security Features**: Automatically verifies checksums, GitHub Attestations, SLSA provenance

4. **Pre-commit Hooks**: Keep using detect-secrets - mise doesn't replace this

## ✅ Success Criteria

You'll know the migration is successful when:

- [ ] `mise doctor` shows no errors
- [ ] `mise list` shows all your tools
- [ ] `mise run lint` passes
- [ ] `mise run info` shows correct tool versions
- [ ] `python --version` matches expected version
- [ ] Tools switch automatically when you `cd` to different projects
- [ ] `mise.lock` is committed to your dotfiles repo
- [ ] CI/CD pipeline still passes (using `setup-mise@v0`)

## 🎉 Next Steps

After completing migration:

1. **Commit mise.lock**:
   ```bash
   git add mise.lock private_dot_config/mise/config.toml.tmpl
   git commit -m "feat: migrate to mise for unified tool management"
   ```

2. **Update Documentation**: Update README.md to reflect mise usage

3. **Create Project Configs**: Add `.mise.toml` to your projects for per-project versions

4. **Deprecate Old Methods**: Remove or redirect Makefile targets to mise

5. **Share with Team**: Help teammates migrate using this guide

## 💬 Feedback

If you find issues or have suggestions for improving this configuration:

1. Open an issue in the dotfiles repo
2. Propose changes via PR
3. Update this guide with lessons learned

---

**Happy mise-ing! 🎉**
