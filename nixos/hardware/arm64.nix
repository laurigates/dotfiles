# ARM64 hardware configuration (Raspberry Pi, etc.)
{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  networking.hostName = "arm64";

  # ARM64 platform
  nixpkgs.hostPlatform = "aarch64-linux";

  # Boot configuration for UEFI ARM
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "usbhid"
    "sd_mod"
  ];

  # For Raspberry Pi (uncomment if applicable)
  # boot.loader = {
  #   grub.enable = false;
  #   generic-extlinux-compatible.enable = true;
  # };

  # Example filesystem (replace with actual)
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-YOUR-UUID";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-BOOT-UUID";
    fsType = "vfat";
  };

  # Enable hardware for ARM boards
  hardware.enableRedistributableFirmware = true;

  # Cross-compilation support (if building for ARM from x86)
  # boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # GPU support varies by board - configure as needed
  hardware.graphics.enable = true;
}
