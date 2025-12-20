# Security configuration
{ config, pkgs, lib, ... }:

{
  # Sudo configuration
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
    extraConfig = ''
      # Increase sudo timeout to 15 minutes
      Defaults timestamp_timeout=15
      # Allow running specific commands without password (optional)
      # %wheel ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/nixos-rebuild
    '';
  };

  # Polkit for privilege escalation in GUI apps
  security.polkit.enable = true;

  # PAM configuration
  security.pam = {
    # Enable u2f support (YubiKey, etc.)
    # u2f.enable = true;

    # Login delays after failed attempts
    loginLimits = [
      {
        domain = "*";
        type = "soft";
        item = "nofile";
        value = "65536";
      }
      {
        domain = "*";
        type = "hard";
        item = "nofile";
        value = "524288";
      }
    ];
  };

  # AppArmor (optional, can conflict with some development tools)
  # security.apparmor.enable = true;

  # Audit logging
  security.auditd.enable = false; # Enable for security auditing

  # Kernel hardening
  boot.kernel.sysctl = {
    # Disable magic SysRq key (security)
    "kernel.sysrq" = 0;

    # Restrict dmesg access
    "kernel.dmesg_restrict" = 1;

    # Hide kernel pointers
    "kernel.kptr_restrict" = 2;

    # Restrict ptrace
    "kernel.yama.ptrace_scope" = 1;

    # Network hardening
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;

    # Increase inotify limits for development tools
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 1024;
  };

  # Automatic security updates (optional)
  # To enable, set 'enable = true' and update the flake path to match your setup.
  # The flake path should point to your NixOS configuration directory.
  # Example: "/home/<username>/.config/nixos#<configuration-name>"
  system.autoUpgrade = {
    enable = false;
    allowReboot = false;
    dates = "04:00";
    # Flake path - update this to match your username and configuration
    # flake = "/home/lgates/.config/nixos#workstation";
  };
}
