# NixOS Configuration

NixOS configuration extrapolated from dotfiles preferences. This provides a fully declarative, reproducible development environment.

## Quick Start

### Installation on NixOS

1. Clone this repository:
   ```bash
   git clone https://github.com/laurigates/dotfiles.git
   cd dotfiles/nixos
   ```

2. Generate hardware configuration:
   ```bash
   sudo nixos-generate-config --show-hardware-config > hardware/my-hardware.nix
   ```

3. Update `flake.nix` to add your machine:
   ```nix
   nixosConfigurations.mymachine = nixpkgs.lib.nixosSystem {
     system = "x86_64-linux";
     specialArgs = { inherit inputs user; };
     modules = [
       commonNixosModule
       ./configuration.nix
       ./hardware/my-hardware.nix
       home-manager.nixosModules.home-manager
       {
         home-manager = {
           useGlobalPkgs = true;
           useUserPackages = true;
           extraSpecialArgs = { inherit inputs user; };
           users.${user.name} = import ./home.nix;
         };
       }
     ];
   };
   ```

4. Update user configuration in `flake.nix`:
   ```nix
   user = {
     name = "yourusername";
     fullName = "Your Full Name";
     email = "your@email.com";
     home = "/home/yourusername";
   };
   ```

5. Build and switch:
   ```bash
   sudo nixos-rebuild switch --flake .#mymachine
   ```

### Standalone Home Manager (non-NixOS)

For use on other Linux distributions:

```bash
# Install Nix
sh <(curl -L https://nixos.org/nix/install) --daemon

# Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Apply home-manager configuration
nix run home-manager/master -- switch --flake .#lgates@linux
```

## Directory Structure

```
nixos/
├── flake.nix           # Main flake with inputs and system configs
├── configuration.nix   # NixOS system configuration
├── home.nix            # Home Manager main configuration
├── hardware/
│   ├── generic.nix     # Generic hardware template
│   ├── laptop.nix      # Laptop with power management
│   └── arm64.nix       # ARM64 (Raspberry Pi, etc.)
├── modules/
│   ├── networking.nix  # Network configuration
│   ├── security.nix    # Security hardening
│   └── virtualization.nix  # Docker, Podman, KVM
└── home/
    ├── shell.nix       # Zsh, Fish, Starship
    ├── neovim.nix      # Neovim with plugins
    ├── git.nix         # Git, GitHub CLI, Lazygit
    ├── development.nix # Language configs, linters
    └── terminal.nix    # Kitty, Tmux, Zellij
```

## Configurations Included

### System (configuration.nix)
- Latest kernel with performance optimizations
- Pipewire audio (modern replacement for PulseAudio)
- Docker and Podman containers
- QEMU/KVM virtualization
- Tailscale VPN
- Firmware updates via fwupd
- USB device access for embedded development

### Shell (home/shell.nix)
- **Zsh** as primary shell with syntax highlighting, autosuggestions
- **Fish** as alternative shell
- **Starship** prompt with git status, language versions
- **FZF** for fuzzy finding with bat/eza previews
- Comprehensive aliases for git, docker, kubernetes, terraform
- Atuin for shell history
- Zoxide for directory jumping

### Editor (home/neovim.nix)
- Neovim with lazy.nvim plugin manager
- **TokyoNight** colorscheme
- Treesitter for syntax highlighting
- Native LSP with blink.cmp completion
- Conform for formatting (stylua, prettier, ruff, etc.)
- nvim-lint for linting (shellcheck, yamllint, etc.)
- fzf-lua for fuzzy finding
- oil.nvim for file management
- gitsigns for git integration
- Which-key for keybind discovery

### Git (home/git.nix)
- Delta for beautiful diffs
- Comprehensive aliases
- GPG signing ready
- GitHub CLI with extensions
- Lazygit TUI
- Global gitignore patterns

### Terminal (home/terminal.nix)
- **Kitty** terminal with TokyoNight colors
- **Tmux** with vim-style navigation, session persistence
- **Zellij** as modern alternative
- **Alacritty** as minimal fallback

### Development (home/development.nix)
- Ruff configuration for Python
- golangci-lint for Go
- Cargo aliases for Rust
- EditorConfig for consistent formatting
- Prettier for JS/TS
- ripgrep and fd configurations
- Pre-commit template
- Docker and Kubernetes configs

## Package Categories

### CLI Tools (Rust-based, fast)
- ripgrep, fd, bat, eza, lsd, delta, zoxide, dust, procs, bottom

### Development Tools
- Language servers for all major languages
- Formatters: stylua, prettier, ruff, gofumpt, rustfmt, shfmt
- Linters: shellcheck, hadolint, actionlint, tflint, trivy

### Languages & Runtimes
- Python 3.13 with uv package manager
- Node.js 22 with Bun
- Go 1.23
- Rust via rustup

### DevOps
- Docker, Podman, dive, lazydocker
- kubectl, k9s, helm, argocd
- Terraform, terragrunt
- AWS CLI, Google Cloud SDK, Ansible

### Security
- age, sops, gnupg, gopass
- trufflehog, gitleaks
- trivy

## Common Commands

```bash
# Rebuild system
nrs                              # alias for: sudo nixos-rebuild switch --flake .#

# Update flake inputs
nfu                              # alias for: nix flake update

# Garbage collection
ngc                              # alias for: nix-collect-garbage -d
nsgc                             # alias for: sudo nix-collect-garbage -d

# Edit configurations
enix                             # Edit flake.nix
ehome                            # Edit home.nix
```

## Customization

### Adding Packages

Edit `home.nix` and add packages to `home.packages`:

```nix
home.packages = with pkgs; [
  # Add your packages here
  slack
  discord
];
```

### Adding a New Machine

1. Create hardware config in `hardware/`
2. Add nixosConfiguration in `flake.nix`
3. Rebuild with `sudo nixos-rebuild switch --flake .#newmachine`

### Changing Theme

The configuration uses TokyoNight. To change:

1. Update Neovim colorscheme in `home/neovim.nix`
2. Update Kitty/Alacritty colors in `home/terminal.nix`
3. Update Starship colors in `home/shell.nix`

## Relationship to Chezmoi

This NixOS configuration is **complementary** to the chezmoi dotfiles:

- **Chezmoi**: Manages dotfiles cross-platform (macOS + Linux)
- **NixOS**: Provides declarative system + user configuration

You can:
1. Use NixOS alone for fully declarative setup
2. Use NixOS for packages + chezmoi for dotfiles
3. Symlink chezmoi configs into NixOS home-manager

Example symlink approach in `home/neovim.nix`:
```nix
xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink
  "${config.home.homeDirectory}/.local/share/chezmoi/private_dot_config/nvim";
```

## Troubleshooting

### Build Errors

```bash
# Check flake
nix flake check

# Build without switching
sudo nixos-rebuild build --flake .#mymachine

# Verbose output
sudo nixos-rebuild switch --flake .#mymachine --show-trace
```

### Missing Hardware Config

```bash
# Generate hardware configuration
sudo nixos-generate-config --show-hardware-config

# Check filesystem UUIDs
blkid
```

### Rollback

```bash
# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous
sudo nixos-rebuild switch --rollback
```
