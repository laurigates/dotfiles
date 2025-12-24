# Networking configuration
{ config, pkgs, lib, ... }:

{
  networking = {
    # Set hostname (override in hardware-specific config)
    hostName = lib.mkDefault "nixos";

    # Use NetworkManager for easy network management
    networkmanager = {
      enable = true;
      wifi.powersave = true;
    };

    # Firewall configuration
    firewall = {
      enable = true;
      allowPing = true;
      # Common development ports (adjust as needed)
      allowedTCPPorts = [
        22    # SSH
        # 80    # HTTP
        # 443   # HTTPS
        # 3000  # Dev server
        # 8080  # Alternative HTTP
      ];
      allowedUDPPorts = [
        # 1883  # MQTT
      ];
      # Tailscale interface is trusted
      trustedInterfaces = [ "tailscale0" ];
    };

    # DNS configuration
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "8.8.8.8"
    ];

    # Enable mDNS for local network discovery
    # networkmanager handles this, but explicit for clarity
  };

  # Avahi for mDNS/DNS-SD
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # Resolved for DNS (optional, comment out if using NetworkManager DNS)
  # services.resolved = {
  #   enable = true;
  #   dnssec = "allow-downgrade";
  #   fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
  # };
}
