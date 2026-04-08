# ADR-0013: NixOS Configuration for Declarative System Management

## Status

Accepted

## Date

2025-12

## Context

The dotfiles repository has evolved into a sophisticated cross-platform configuration system using chezmoi and mise. However, for NixOS users, there's an opportunity to achieve even greater reproducibility through fully declarative system configuration.

### Current State

The repository already manages:
- **Dotfiles**: Via chezmoi with templates and cross-platform support
- **Tool versions**: Via mise with lockfile for reproducibility
- **Shell configuration**: Zsh/Fish with comprehensive aliases
- **Editor setup**: Neovim with lazy.nvim and 75+ plugins
- **Development tools**: Language runtimes, formatters, linters

### The Gap

While chezmoi + mise provides excellent user-level configuration, it doesn't address:

1. **System-level packages**: Kernel, drivers, system services
2. **Declarative services**: Docker, Tailscale, SSH daemon configuration
3. **Atomic upgrades**: Rollback to previous system state
4. **Full reproducibility**: Same system on any machine from single config

### Why NixOS Now?

Several factors motivated adding NixOS support:

1. **Complementary approach**: NixOS doesn't replace chezmoi—they work together
2. **User preference extrapolation**: Existing configs reveal clear tool preferences
3. **Home Manager integration**: Bridges NixOS and traditional dotfiles
4. **CI/Server use case**: Declarative server configurations for homelab

### Relationship to ADR-0002 (mise)

ADR-0002 rejected Nix/home-manager as "overkill for tool versions." This ADR takes a different view:

| ADR-0002 Position | ADR-0013 Position |
|-------------------|-------------------|
| Nix for tool versions = overkill | NixOS for full system = appropriate |
| mise provides reproducibility | NixOS provides atomic rollbacks |
| Cross-platform (macOS + Linux) | Linux-only (NixOS + home-manager) |

**Key insight**: mise handles tools on macOS + traditional Linux. NixOS handles full system declarativity when that's desired. They're not competing—they serve different use cases.

## Decision

**Add NixOS configuration to the dotfiles repository** as an optional, complementary configuration method for NixOS users.

### Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                   Configuration Approaches                      │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Traditional (macOS/Linux)         NixOS                       │
│  ─────────────────────────         ──────                       │
│  • chezmoi for dotfiles            • flake.nix for system      │
│  • mise for tool versions          • home.nix for user config  │
│  • Homebrew for bootstrap          • Declarative packages      │
│                                                                 │
│                     ┌──────────────┐                           │
│                     │   Shared     │                           │
│                     │  Principles  │                           │
│                     ├──────────────┤                           │
│                     │ • TokyoNight │                           │
│                     │ • Zsh + Fish │                           │
│                     │ • Neovim     │                           │
│                     │ • Git config │                           │
│                     │ • Aliases    │                           │
│                     └──────────────┘                           │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

### Directory Structure

```
nixos/
├── flake.nix              # Flake with inputs and system definitions
├── configuration.nix      # NixOS system configuration
├── home.nix               # Home Manager entry point
├── README.md              # Usage documentation
├── hardware/
│   ├── generic.nix        # Desktop workstation template
│   ├── laptop.nix         # Laptop with power management
│   └── arm64.nix          # Raspberry Pi / ARM boards
├── modules/
│   ├── networking.nix     # NetworkManager, firewall
│   ├── security.nix       # Hardening, PAM, sudo
│   └── virtualization.nix # Docker, Podman, QEMU/KVM
└── home/
    ├── shell.nix          # Zsh, Fish, Starship, FZF
    ├── neovim.nix         # Editor with lazy.nvim
    ├── git.nix            # Git, GitHub CLI, Lazygit
    ├── development.nix    # Language configs, linters
    └── terminal.nix       # Kitty, Tmux, Zellij
```

### Preference Extrapolation

Configurations were derived by analyzing existing dotfiles:

| Source | Derived NixOS Config |
|--------|---------------------|
| `Brewfile` | System packages, services |
| `mise/config.toml.tmpl` | Language runtimes |
| `dot_zshrc.tmpl`, `aliases.zsh` | Shell configuration, 60+ aliases |
| `nvim/init.lua`, `nvim/lua/` | Neovim plugins and LSP |
| `dot_tmux.conf` | Tmux configuration |
| `starship.toml` | Starship prompt theme |
| `.chezmoidata.toml` | Python tools, MCP servers |

### Configuration Options

Three NixOS configurations for different hardware:

1. **workstation**: Generic desktop with full development setup
2. **laptop**: TLP power management, battery thresholds, touchpad
3. **arm64**: Raspberry Pi and ARM server support

Plus standalone home-manager for non-NixOS Linux:

```bash
# NixOS full system
sudo nixos-rebuild switch --flake .#workstation

# Home Manager only (Ubuntu, Fedora, etc.)
home-manager switch --flake .#lgates@linux
```

### Integration Strategies

Users can choose their integration level:

**Option A: NixOS-only** (full declarative)
- All configs in Nix
- No chezmoi needed
- Maximum reproducibility

**Option B: NixOS + Chezmoi hybrid** (recommended)
- NixOS for system + packages
- Chezmoi for dotfiles (symlinked)
- Familiar editing workflow

**Option C: Home Manager standalone**
- Keep existing distro (Ubuntu, Fedora)
- Use home-manager for user config
- Gradual adoption path

## Consequences

### Positive

1. **Full system reproducibility**: Rebuild identical system from flake
2. **Atomic rollbacks**: `nixos-rebuild switch --rollback` for instant recovery
3. **Unified packages**: All tools declared in one place
4. **Multi-machine**: Same config across desktop, laptop, servers
5. **Preference preservation**: Existing tool choices honored
6. **Modular design**: Pick modules you need

### Negative

1. **Learning curve**: Nix language syntax is unique
2. **Linux-only**: NixOS doesn't run on macOS (Darwin support is separate)
3. **Maintenance burden**: Two config systems to maintain
4. **Build times**: Initial system builds can be slow
5. **Disk usage**: Nix store accumulates generations

### Trade-offs

| Aspect | chezmoi + mise | NixOS |
|--------|----------------|-------|
| Learning curve | Lower | Higher |
| Cross-platform | macOS + Linux | Linux only |
| Rollback | Manual | Atomic, instant |
| Disk usage | Minimal | ~10-30GB for store |
| Package availability | Homebrew ecosystem | Nixpkgs (80,000+) |
| Configuration style | File templates | Functional (Nix lang) |

### Migration Path

1. **Test in VM**: Try NixOS config in QEMU/VirtualBox first
2. **Home Manager first**: Use standalone home-manager on existing distro
3. **Dual boot**: Install NixOS alongside current distro
4. **Full migration**: Replace primary system when comfortable

## Alternatives Considered

### Ansible for System Configuration

**Rejected because**:
- Imperative rather than declarative
- No atomic rollbacks
- Drift between runs possible
- Overkill for personal workstation

### Ignoring NixOS Users

**Rejected because**:
- Growing NixOS user base
- Natural fit for declarative dotfiles philosophy
- Requested by users of the dotfiles repo

### Full Nix Darwin (macOS)

**Deferred because**:
- Additional complexity
- Homebrew works well on macOS
- Can add later as separate configuration

### Replace chezmoi with Nix

**Rejected because**:
- chezmoi works cross-platform
- Familiar to existing users
- Hybrid approach is more flexible

## Related Decisions

- **ADR-0001**: Chezmoi exact_ Directory Strategy (atomic updates philosophy shared)
- **ADR-0002**: Unified Tool Version Management with Mise (complementary on traditional Linux)
- **ADR-0007**: Layered Knowledge Distribution (modular config approach)

## References

- NixOS Manual: https://nixos.org/manual/nixos/stable/
- Home Manager: https://nix-community.github.io/home-manager/
- Nix Flakes: https://nixos.wiki/wiki/Flakes
- Configuration: `nixos/` directory
- Usage guide: `nixos/README.md`
