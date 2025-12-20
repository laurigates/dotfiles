{
  description = "NixOS configuration for lgates - extrapolated from dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Neovim nightly builds
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Rust toolchain
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware optimizations
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Declarative disk partitioning (optional)
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Catppuccin theming (alternative to TokyoNight)
    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, home-manager, neovim-nightly-overlay, rust-overlay, nixos-hardware, disko, catppuccin, ... }@inputs:
    let
      # Supported systems
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # User configuration
      user = {
        name = "lgates";
        fullName = "Lauri Gates";
        email = "lauri.gates@example.com"; # Update this
        home = "/home/lgates";
      };

      # Overlays
      overlays = [
        neovim-nightly-overlay.overlays.default
        rust-overlay.overlays.default
        (final: prev: {
          # Pin stable packages when needed
          stable = nixpkgs-stable.legacyPackages.${prev.system};
        })
      ];

      # NixOS module for common configuration
      commonNixosModule = { config, pkgs, lib, ... }: {
        nixpkgs.overlays = overlays;
        nixpkgs.config.allowUnfree = true;

        nix = {
          settings = {
            experimental-features = [ "nix-command" "flakes" ];
            auto-optimise-store = true;
            trusted-users = [ "root" user.name ];
            substituters = [
              "https://cache.nixos.org"
              "https://nix-community.cachix.org"
            ];
            trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            ];
          };
          gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 30d";
          };
        };
      };

    in {
      # NixOS configurations
      nixosConfigurations = {
        # Generic workstation configuration
        workstation = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs user; };
          modules = [
            commonNixosModule
            ./configuration.nix
            ./hardware/generic.nix
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

        # Laptop configuration (with power management)
        laptop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs user; };
          modules = [
            commonNixosModule
            ./configuration.nix
            ./hardware/laptop.nix
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

        # ARM64 configuration (Raspberry Pi, etc.)
        arm64 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs user; };
          modules = [
            commonNixosModule
            ./configuration.nix
            ./hardware/arm64.nix
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
      };

      # Home Manager standalone configurations (for non-NixOS)
      homeConfigurations = {
        "${user.name}@linux" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs user; };
          modules = [
            { nixpkgs.overlays = overlays; }
            ./home.nix
          ];
        };
      };

      # Development shells
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              nixpkgs-fmt
              nil # Nix LSP
              statix # Nix linter
              deadnix # Find unused Nix code
            ];
          };
        }
      );

      # Formatter
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
    };
}
