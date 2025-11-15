# Homebrew to mise Migration Analysis

This document analyzes package duplication between Homebrew and the new mise configuration.

## 📊 Duplicate Analysis

### Packages Now Managed by mise (Remove from Homebrew)

#### Runtimes
| Homebrew Package | mise Equivalent | Backend |
|-----------------|-----------------|---------|
| `python@3.11` | `python = ["3.11", "3.13"]` | core |
| `python@3.13` | `python = ["3.11", "3.13"]` | core |
| `oven-sh/bun/bun` | `bun = "latest"` | core |

Note: node, go, rust not in Homebrew list, so no conflicts.

#### CLI Tools via aqua Backend
| Homebrew Package | mise Equivalent | Security Benefit |
|-----------------|-----------------|------------------|
| `kubernetes-cli` | `aqua:kubernetes/kubernetes` | ✅ Attestations + SLSA |
| `helm` | `aqua:helm/helm` | ✅ Attestations + SLSA |
| `argocd` | `aqua:argoproj/argo-cd` | ✅ Attestations + SLSA |
| `kubectx` | `aqua:ahmetb/kubectx` | ✅ Checksums |
| `k9s` | `aqua:derailed/k9s` | ✅ Checksums |
| `skaffold` | `aqua:kubernetes-sigs/skaffold` | ✅ Attestations + SLSA |
| `hashicorp/tap/terraform` | `aqua:hashicorp/terraform` | ✅ Checksums |
| `lazygit` | `aqua:jesseduffield/lazygit` | ✅ Checksums |
| `jq` | `aqua:jqlang/jq` | ✅ Checksums |
| `ripgrep` | `aqua:BurntSushi/ripgrep` | ✅ Checksums |
| `fd` | `aqua:sharkdp/fd` | ✅ Checksums |
| `bat` | `aqua:sharkdp/bat` | ✅ Checksums |
| `lsd` | `aqua:lsd-rs/lsd` | ✅ Checksums |
| `git-delta` | `aqua:dandavison/delta` | ✅ Checksums |
| `zoxide` | `aqua:ajeetdsouza/zoxide` | ✅ Checksums |
| `atuin` | `aqua:atuin-sh/atuin` | ✅ Checksums |
| `gh` | `aqua:cli/cli` | ✅ Attestations + SLSA |

**Total: 20 packages to remove**

#### Taps No Longer Needed
| Tap | Reason |
|-----|--------|
| `hashicorp/tap` | terraform now via aqua |
| `oven-sh/bun` | bun now via mise runtime |

### Python Tools (Keep in uv_tools for now)

**Decision**: Keep the 18 Python tools in `uv_tools` section of `.chezmoidata.toml` during migration phase.

**Reasoning**:
- The `run_onchange_01-update-packages.sh.tmpl` script still uses these
- Allows gradual migration: Homebrew → mise → test → remove uv tools
- No harm in having both defined during transition
- Users can manually run `uv tool uninstall` after confirming mise versions work

**Future**: After migration is complete, can remove `uv_tools` section entirely since mise handles these via `pipx:` backend.

### Package to REMOVE (Not Needed Anymore)

| Package | Reason |
|---------|--------|
| `pipx` | mise's pipx backend uses uvx (from uv package) directly |

Note: Keep `uv` in Homebrew - mise's pipx backend depends on it for uvx.

---

## ✅ Packages to KEEP in Homebrew

### Bootstrap & Core Tools
- `chezmoi` - needed before mise can run
- `git` - core version control
- `fish` - shell, needs OS integration
- `uv` - mise uses it for uvx in pipx backend
- `mise` - manages other tools

### Build & Development Tools
- `autoconf`, `cmake`, `ninja` - build systems
- `groff`, `help2man` - documentation tools
- `luarocks` - Lua package manager (for Neovim)
- `maven` - Java build tool
- `tcl-tk` - Tk toolkit

### System Utilities
- `coreutils`, `curl`, `netcat` - core Unix tools
- `fswatch` - file change monitor
- `parallel` - GNU parallel
- `fzf` - fuzzy finder (used by shell configs)
- `starship` - shell prompt

### Security & Network Tools
- `binwalk`, `gobuster`, `nmap`, `trufflehog` - security tools
- `wireshark` - network analyzer
- `iperf3` - network performance
- `httpie` - HTTP client

### Specialized Development Tools
- `arduino-cli` - Arduino development
- `platformio` - IoT development
- `ast-grep` - code search tool
- `dbmate` - database migrations
- `dfu-util` - firmware flashing
- `git-filter-repo`, `git-lfs` - git tools
- `so` - Stack Overflow CLI
- `tflint` - Terraform linter
- `tldr` - simplified man pages
- `mermaid-cli` - diagram generation
- `pandoc` - document converter

### System Services & Daemons
- `mosquitto` - MQTT broker
- `ollama` - AI model server
- `postgresql@14`, `postgresql@16` - databases (macOS)
- `lldpd` - network discovery (macOS)

### Libraries & Dependencies
- `gnutls`, `zlib` - libraries
- `imagemagick` - image processing
- `qemu` - virtualization

### Shell & Terminal
- `nushell` - alternative shell
- `ranger` - file manager
- `zsh-completions` - zsh completions

### Other Tools Without aqua Equivalents
- `knqyf263/pet/pet` - snippet manager
- `norwoodj/tap/helm-docs` - Helm documentation
- `argocd-vault-plugin` - ArgoCD plugin
- `jd` - JSON diff tool

### Platform-Specific (macOS)
All darwin-specific packages stay in Homebrew.

### Casks & GUI Apps
All casks stay in Homebrew (Ghostty, Obsidian, VS Code, etc.)

---

## 🎯 Removal Strategy

### Phase 1: Safe Removals (Now)
Remove packages that are definitely duplicated and tested in mise:
- Python runtimes (python@3.11, python@3.13)
- Common CLI tools (kubectl, helm, ripgrep, fd, bat, etc.)
- Taps for removed packages

### Phase 2: Verify & Clean (After Testing)
After confirming mise-installed tools work:
- Remove `pipx` from Homebrew
- Update completion tools list if needed

### Phase 3: Python Tools (Optional)
After full mise migration:
- Remove `uv_tools` section from `.chezmoidata.toml`
- Keep `uv` in Homebrew (used by mise)

---

## 📋 Changes Summary

**Homebrew packages to remove**: 20
**Taps to remove**: 2
**Packages to keep**: ~60+ (majority of current packages)
**Python tools**: Keep in uv_tools for now (gradual migration)

**Impact**:
- Smaller Brewfile = faster `brew bundle` operations
- Reduced duplication = clearer dependency management
- Better security = aqua backend verification for CLI tools
- Version pinning = mise.lock for reproducibility

**Risk Level**: ⚠️ **Medium**
- Ensure mise tools are installed before removing Homebrew versions
- Test critical tools (kubectl, helm, terraform) before removal
- Keep backups or ability to rollback
- Consider doing removals in batches

---

## 🚀 Recommended Action Plan

1. **Apply mise config** (already done via chezmoi apply)
2. **Install mise tools**: `mise install`
3. **Test critical tools**:
   ```bash
   mise exec -- kubectl version
   mise exec -- helm version
   mise exec -- terraform version
   mise exec -- python --version
   ```
4. **Verify PATH**: Ensure mise-managed tools are in PATH
5. **Remove Homebrew duplicates**: Update `.chezmoidata.toml`
6. **Re-apply dotfiles**: `chezmoi apply`
7. **Clean Homebrew**: `brew bundle cleanup --force` (optional)

---

## ⚠️ Important Notes

- **Don't remove `uv`** - mise's pipx backend depends on it
- **Keep `chezmoi`, `git`, `fish`, `mise`** - bootstrap/core tools
- **Test before removing** - ensure mise versions work first
- **Gradual migration** - can remove in phases if preferred
- **Homebrew services** - keep packages that run as services
- **Platform-specific** - keep OS-specific packages in Homebrew

---

## 📝 Completion Tools Impact

These tools in `zsh_completions` will still work after moving to mise:
- `kubectl`, `helm`, `argocd`, `skaffold` - completions work via mise exec
- `rg`, `fd` - completions work via mise exec
- `gh`, `atuin` - completions work via mise exec

The completion generation script should handle mise-managed tools automatically.
