# Home Manager configuration - extrapolated from dotfiles preferences
# This is the main user-level configuration

{ config, pkgs, lib, user, inputs, ... }:

{
  imports = [
    ./home/shell.nix
    ./home/neovim.nix
    ./home/git.nix
    ./home/development.nix
    ./home/terminal.nix
  ];

  # Home Manager basics
  home = {
    username = user.name;
    homeDirectory = user.home;
    stateVersion = "24.11";

    # Session variables
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less";
      MANPAGER = "nvim +Man!";
      BROWSER = "firefox";

      # XDG directories
      XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
      XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
      XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache";
      XDG_STATE_HOME = "${config.home.homeDirectory}/.local/state";

      # Development
      CARGO_HOME = "${config.home.homeDirectory}/.cargo";
      GOPATH = "${config.home.homeDirectory}/go";
      RUSTUP_HOME = "${config.home.homeDirectory}/.rustup";

      # FZF (from dotfiles)
      FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border --info=inline";

      # Less configuration
      LESS = "-R --use-color -Dd+r$Du+b";
      LESSHISTFILE = "-";
    };

    # Session path
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.cargo/bin"
      "$HOME/go/bin"
      "$HOME/.npm-global/bin"
    ];
  };

  # Enable Home Manager
  programs.home-manager.enable = true;

  # User packages (from Brewfile, mise, aqua, etc.)
  home.packages = with pkgs; [
    # === Core CLI Tools (Rust-based, fast) ===
    ripgrep        # rg - code search (replaces grep)
    fd             # File finding (replaces find)
    bat            # Syntax-highlighted cat
    eza            # Modern ls replacement (successor to exa)
    lsd            # LSDeluxe (ls with icons)
    delta          # Git diff viewer
    zoxide         # Directory jumping
    du-dust        # Disk usage (dust)
    procs          # Modern ps replacement
    bottom         # System monitor (btm)
    sd             # Modern sed replacement
    choose         # Cut alternative
    tealdeer       # tldr client
    hyperfine      # Benchmarking
    tokei          # Code statistics
    bandwhich      # Network monitor
    grex           # Regex builder

    # === Development Tools ===
    # Build tools
    gnumake
    cmake
    ninja
    meson
    pkg-config
    autoconf
    automake
    libtool

    # Language servers & tools (for Neovim)
    nil            # Nix LSP
    nixpkgs-fmt    # Nix formatter
    lua-language-server
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted  # HTML, CSS, JSON
    pyright        # Python LSP
    gopls          # Go LSP
    rust-analyzer  # Rust LSP
    terraform-ls   # Terraform LSP
    yaml-language-server
    marksman       # Markdown LSP
    taplo          # TOML LSP

    # Linters & formatters
    shellcheck
    shfmt
    stylua
    ruff           # Python linter/formatter
    nodePackages.prettier
    nodePackages.eslint
    actionlint     # GitHub Actions linter
    hadolint       # Dockerfile linter
    yamllint
    statix         # Nix linter
    deadnix        # Find dead Nix code
    tflint         # Terraform linter
    trivy          # Security scanner
    commitlint     # Commit message linter
    pre-commit

    # === Programming Languages & Runtimes ===
    # Python (via uv ecosystem)
    python313
    uv             # Fast Python package manager
    rye            # Python project manager

    # Node.js
    nodejs_22
    nodePackages.npm
    bun            # Fast JS runtime

    # Go
    go_1_23
    golangci-lint
    delve          # Go debugger

    # Rust (via rustup)
    rustup
    cargo-watch
    cargo-edit
    cargo-outdated
    cargo-audit
    cargo-expand

    # Lua
    lua5_4
    luarocks

    # === DevOps & Infrastructure ===
    # Containers
    docker-compose
    dive           # Docker image explorer
    lazydocker     # Docker TUI
    skopeo         # Container image tools
    buildah        # Container builder

    # Kubernetes
    kubectl
    kubectx        # Context switcher
    kubens         # Namespace switcher
    k9s            # Kubernetes TUI
    helm
    helmfile
    kustomize
    stern          # Multi-pod log tailing
    kubeseal       # Sealed secrets
    argocd         # GitOps

    # Cloud & Infrastructure
    terraform
    terragrunt
    awscli2
    google-cloud-sdk
    ansible

    # === Git & Version Control ===
    git-lfs
    git-filter-repo
    gh             # GitHub CLI
    glab           # GitLab CLI
    lazygit        # Git TUI
    # delta is declared above in Core CLI Tools
    git-crypt      # Encrypt files in git

    # === Data & Text Processing ===
    jq             # JSON processor
    yq-go          # YAML processor
    fx             # JSON viewer
    gron           # Make JSON greppable
    xsv            # CSV toolkit
    miller         # CSV/JSON/etc processor
    pandoc         # Document converter
    poppler_utils  # PDF tools

    # === Network & Security ===
    curl
    wget
    httpie         # Modern HTTP client
    xh             # Fast HTTPie alternative
    nmap
    masscan
    iperf3
    mtr            # Network diagnostics
    dog            # DNS client
    termshark      # Wireshark TUI
    netcat-gnu
    socat
    tcpdump

    # Security
    age            # Modern encryption
    sops           # Secret management
    gnupg
    pass           # Password manager
    gopass
    trufflehog     # Secret scanner
    gitleaks       # Git secret scanner

    # === System & Utilities ===
    htop
    btop           # Modern htop
    glances        # System monitor
    ncdu           # Disk usage analyzer
    duf            # Disk usage
    tree
    file
    pv             # Pipe viewer
    parallel       # GNU parallel
    entr           # File watcher
    watchexec      # Command re-runner
    just           # Command runner
    direnv         # Directory environments

    # Archive tools
    unzip
    zip
    p7zip
    unrar
    atool

    # File managers
    ranger
    nnn
    yazi           # Modern file manager

    # === Hardware & Embedded ===
    arduino-cli
    platformio
    esptool
    dfu-util
    minicom        # Serial terminal
    screen
    picocom

    # === Media & Graphics ===
    imagemagick
    ffmpeg
    yt-dlp
    asciinema      # Terminal recording

    # === Communication ===
    # telegram-desktop  # Uncomment if needed

    # === Fonts (in case not installed system-wide) ===
    # (system-wide fonts are configured in configuration.nix)
  ];

  # XDG configuration
  xdg = {
    enable = true;
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    cacheHome = "${config.home.homeDirectory}/.cache";
    stateHome = "${config.home.homeDirectory}/.local/state";

    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
      templates = "${config.home.homeDirectory}/Templates";
      publicShare = "${config.home.homeDirectory}/Public";
    };

    # MIME type associations
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = [ "firefox.desktop" ];
        "text/plain" = [ "nvim.desktop" ];
        "application/pdf" = [ "org.pwmt.zathura.desktop" ];
        "image/*" = [ "imv.desktop" ];
        "video/*" = [ "mpv.desktop" ];
      };
    };
  };

  # Direnv for per-directory environments
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config = {
      global = {
        warn_timeout = "30s";
        hide_env_diff = true;
      };
    };
  };

  # Atuin for shell history
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    settings = {
      auto_sync = false;
      sync_address = "";
      style = "compact";
      inline_height = 20;
      search_mode = "fuzzy";
      filter_mode = "global";
      filter_mode_shell_up_key_binding = "directory";
    };
  };

  # Zoxide for directory jumping
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    options = [ "--cmd" "cd" ];
  };

  # SSH configuration
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    compression = true;
    controlMaster = "auto";
    controlPath = "/tmp/ssh-%u-%r@%h:%p";
    controlPersist = "10m";
    extraConfig = ''
      IdentityFile ~/.ssh/id_ed25519
      IdentityFile ~/.ssh/id_rsa

      Host github.com
        HostName github.com
        User git
        IdentityFile ~/.ssh/id_ed25519

      Host gitlab.com
        HostName gitlab.com
        User git
        IdentityFile ~/.ssh/id_ed25519
    '';
  };

  # GPG configuration
  programs.gpg = {
    enable = true;
    settings = {
      no-greeting = true;
      keyid-format = "0xlong";
      with-fingerprint = true;
      use-agent = true;
      armor = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    defaultCacheTtl = 3600;
    maxCacheTtl = 86400;
    pinentry.package = pkgs.pinentry-curses;
  };

  # Less pager configuration
  programs.less = {
    enable = true;
    keys = ''
      #command
      h left-scroll
      l right-scroll
    '';
  };

  # Man pages
  programs.man = {
    enable = true;
    generateCaches = true;
  };

  # Enable fontconfig
  fonts.fontconfig.enable = true;
}
