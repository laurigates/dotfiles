# NixOS system configuration - extrapolated from dotfiles preferences
# Edit this file to define your system configuration.

{ config, pkgs, lib, user, ... }:

{
  imports = [
    ./modules/networking.nix
    ./modules/security.nix
    ./modules/virtualization.nix
  ];

  # System basics
  system.stateVersion = "24.11";

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };
    # Enable latest kernel for better hardware support
    kernelPackages = pkgs.linuxPackages_latest;
    # Kernel parameters for development workstation
    kernelParams = [ "quiet" "splash" ];
    # tmpfs for faster builds
    tmp.useTmpfs = true;
    tmp.tmpfsSize = "50%";
  };

  # Localization (adjust to your preferences)
  time.timeZone = "Europe/Helsinki";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "en_GB.UTF-8";
      LC_MONETARY = "fi_FI.UTF-8";
    };
  };

  # Console configuration
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # User account
  users.users.${user.name} = {
    isNormalUser = true;
    description = user.fullName;
    home = user.home;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"           # sudo access
      "networkmanager"  # network management
      "docker"          # Docker access
      "libvirtd"        # QEMU/KVM access
      "dialout"         # Serial port access (Arduino, embedded)
      "plugdev"         # USB device access
      "wireshark"       # Packet capture
      "audio"           # Audio devices
      "video"           # Video devices
      "input"           # Input devices
    ];
    # SSH public keys (add your keys here)
    openssh.authorizedKeys.keys = [
      # "ssh-ed25519 AAAA... your-key-comment"
    ];
  };

  # Enable programs at system level
  programs = {
    zsh.enable = true;
    fish.enable = true;
    nix-ld.enable = true; # Run unpatched binaries

    # Git at system level for root operations
    git = {
      enable = true;
      lfs.enable = true;
    };

    # Neovim as default editor
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    # GPG for signing commits
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-curses;
    };

    # Wireshark for packet analysis
    wireshark.enable = true;

    # Steam (if gaming, optional)
    # steam.enable = true;
  };

  # System-level packages (minimal - prefer home-manager)
  environment.systemPackages = with pkgs; [
    # Essential system utilities
    curl
    wget
    git
    vim
    htop
    pciutils
    usbutils
    lsof
    file
    tree
    unzip
    zip
    gnumake

    # Hardware tools
    dmidecode
    smartmontools
    nvme-cli

    # Network diagnostics
    inetutils
    dnsutils
    nmap
    iperf3

    # Build essentials (for native compilation)
    gcc
    clang
    cmake
    ninja
    pkg-config
  ];

  # Environment variables
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER = "less";
    MANPAGER = "nvim +Man!";
  };

  # Shell configuration
  environment.shells = with pkgs; [ zsh fish bash ];

  # Services
  services = {
    # SSH daemon
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = false;
      };
    };

    # Time synchronization
    chrony.enable = true;

    # Firmware updates
    fwupd.enable = true;

    # CUPS printing (if needed)
    printing.enable = true;

    # Pipewire for audio (modern replacement for PulseAudio)
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    # udev rules for hardware access
    udev = {
      packages = with pkgs; [
        platformio-core  # Arduino/ESP32 USB access
        android-udev-rules
      ];
      extraRules = ''
        # ESP32/ESP8266 USB access
        SUBSYSTEM=="usb", ATTR{idVendor}=="10c4", ATTR{idProduct}=="ea60", MODE="0666"
        SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="7523", MODE="0666"

        # Arduino USB access
        SUBSYSTEM=="usb", ATTR{idVendor}=="2341", MODE="0666"
        SUBSYSTEM=="usb", ATTR{idVendor}=="1b4f", MODE="0666"

        # STM32 DFU mode
        SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="df11", MODE="0666"
      '';
    };

    # MQTT broker (for IoT development)
    mosquitto = {
      enable = false; # Enable when needed
      listeners = [{
        port = 1883;
        settings.allow_anonymous = true;
      }];
    };

    # Tailscale VPN (optional but recommended)
    tailscale.enable = true;

    # Automatic TRIM for SSDs
    fstrim = {
      enable = true;
      interval = "weekly";
    };
  };

  # Sound
  hardware.pulseaudio.enable = false; # Using Pipewire instead
  security.rtkit.enable = true; # Realtime for Pipewire

  # Fonts
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      # Nerd fonts for terminal/editor
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.hack
      nerd-fonts.iosevka
      nerd-fonts.meslo-lg
      nerd-fonts.symbols-only

      # General fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira
      fira-code
      source-code-pro
      inter
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Inter" "Noto Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" "Fira Code" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # XDG Portal (for Flatpak, screen sharing, etc.)
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Documentation
  documentation = {
    enable = true;
    man.enable = true;
    dev.enable = true;
    nixos.enable = true;
  };
}
