# Virtualization and containerization configuration
{ config, pkgs, lib, ... }:

{
  # Docker
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
      # WARNING: --volumes removes ALL unused volumes including named volumes with data.
      # Remove --volumes if you want to preserve data in unused volumes.
      flags = [ "--all" "--volumes" ];
    };
    # Use overlay2 storage driver
    storageDriver = "overlay2";
    # Docker daemon configuration
    daemon.settings = {
      # Enable BuildKit for faster builds
      features.buildkit = true;
      # Default address pools for networks
      default-address-pools = [
        { base = "172.17.0.0/16"; size = 24; }
      ];
      # Log rotation
      log-driver = "json-file";
      log-opts = {
        max-size = "10m";
        max-file = "3";
      };
    };
  };

  # Podman (alternative to Docker, rootless by default)
  virtualisation.podman = {
    enable = true;
    dockerCompat = false; # Don't conflict with Docker
    defaultNetwork.settings.dns_enabled = true;
  };

  # QEMU/KVM for virtual machines
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true; # TPM emulation
      ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ];
      };
    };
  };

  # Spice for VM display (better performance than VNC)
  virtualisation.spiceUSBRedirection.enable = true;

  # Enable virt-manager GUI
  programs.virt-manager.enable = true;

  # LXC/LXD containers (optional)
  # virtualisation.lxd.enable = true;

  # Vagrant (optional)
  # virtualisation.vagrant = {
  #   enable = true;
  #   libvirt = true;
  # };

  # OCI containers (declarative Docker/Podman containers)
  # Example of running a container declaratively:
  # virtualisation.oci-containers = {
  #   backend = "docker";
  #   containers = {
  #     nginx = {
  #       image = "nginx:latest";
  #       ports = [ "8080:80" ];
  #       volumes = [ "/var/www:/usr/share/nginx/html" ];
  #     };
  #   };
  # };
}
