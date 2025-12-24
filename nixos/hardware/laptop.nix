# Laptop-specific hardware configuration
# Extends generic.nix with power management and laptop-specific settings

{ config, pkgs, lib, ... }:

{
  imports = [
    ./generic.nix
  ];

  networking.hostName = "laptop";

  # Power management
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  # TLP for advanced power management
  services.tlp = {
    enable = true;
    settings = {
      # CPU settings
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # Platform profile
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      # WiFi power save
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      # USB autosuspend
      USB_AUTOSUSPEND = 1;

      # Battery charge thresholds (ThinkPad, some Dell/ASUS)
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  # Don't use power-profiles-daemon with TLP
  services.power-profiles-daemon.enable = false;

  # Thermald for Intel CPUs
  services.thermald.enable = true;

  # UPower for battery monitoring
  services.upower.enable = true;

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false; # Save power
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };
  services.blueman.enable = true;

  # Backlight control
  programs.light.enable = true;
  services.actkbd = {
    enable = true;
    bindings = [
      { keys = [ 224 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -U 10"; }
      { keys = [ 225 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -A 10"; }
    ];
  };

  # Lid switch behavior
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "ignore";
    lidSwitchDocked = "ignore";
  };

  # Touchpad support
  services.libinput = {
    enable = true;
    touchpad = {
      tapping = true;
      naturalScrolling = true;
      scrollMethod = "twofinger";
      disableWhileTyping = true;
      middleEmulation = true;
    };
  };

  # Fingerprint reader (uncomment if available)
  # services.fprintd.enable = true;

  # Auto-suspend on battery
  services.udev.extraRules = ''
    # Suspend on low battery
    SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-5]", RUN+="${pkgs.systemd}/bin/systemctl hibernate"
  '';
}
