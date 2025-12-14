# mix.nix configuration
#
# Declarative host and user definitions using mix.nix library.
# This file is imported as a flake-parts module.
#
# Available in modules via specialArgs:
#   - `host` - Current host spec (host.user, host.desktop, etc.)
#   - `inputs` - All flake inputs
#   - `secrets` - Secrets if configured via mix.secrets
#
{ lib, ... }:
{
  # No imports; Both hostSpec and secrets are handled by mix.nix directly

  mix =
    let
      userGroups = [
        # Common groups for all users
        "adbusers"
        "audio"
        "docker"
        "gamemode"
        "git"
        "i2c"
        "input"
        "libvirtd"
        "networkmanager"
        "video"
        "wheel"
      ];

      wgEndpoint = "pangolin.ryot.foo:51821";
    in
    {
      ## Secrets ##
      secrets = {
        file = ./secrets.nix;
        gitattributes = ../.gitattributes;
      };

      ## mix.nix Configurations ##
      hostsDir = ../hosts; # NixOS configs: hosts/<hostname>/
      hostsHomeDir = ../home/hosts; # HM configs: home/hosts/<hostname>/
      usersHomeDir = ../home/users; # HM configs: home/users/<username>/

      # Global special arguments
      specialArgs =
        let
          flakeRoot = ../.;
        in
        {
          inherit flakeRoot;
        };

      # Core modules applied to ALL hosts
      coreModules = [
        ../modules/hosts/core
      ];

      # Core Home Manager modules applied to ALL users with HM enabled
      coreHomeModules = [
        ../modules/home/core
      ];

      ## Users ##
      users = {
        toph = {
          name = "toph";
          uid = 1000;
          shell = "fish";
          extraGroups = userGroups;
        };

        cesar = {
          name = "cesar";
          shell = "fish";
          extraGroups = userGroups;
        };
      };

      ## Hosts ##
      # Hosts reference users by name and define per-host settings
      hosts = {
        # ── ARM Hosts ──
        caenus = {
          user = "toph";
          system = "aarch64-linux";
          isServer = true;
          isMinimal = true;
        };

        # ── x86 Desktops ──
        haze = {
          user = "cesar";
          ip = "10.19.89.13";
          desktop = "niri";
          mounts = {
            repo = true;
            tank = true;
          };
        };

        norion = {
          user = "toph";
          ip = "10.2.2.4";
          desktop = "gnome";
          mounts = {
            fast = true;
            repo = true;
            store = true;
            tank = true;
          };
          vpn = {
            publicKey = "ECl4YWWZfuAdYesxSUOSq7mTIYwII/eYg78dLR9XpmU=";
            address = "10.10.0.4/32";
            endpoint = wgEndpoint;
          };
        };

        rune = {
          user = "toph";
          ip = "10.4.4.4";
          desktop = "niri";
          mounts = {
            fast = true;
            repo = true;
            store = true;
            tank = true;
          };
        };

        vm = {
          user = "toph";
          desktop = "gnome";
        };

        # ── x86 Servers ──
        nexus = {
          user = "toph";
          ip = "10.1.1.1";
          isServer = true;
          isMinimal = true;
          mounts.repo = true;
          vpn = {
            publicKey = "iOSuhmjJhUcqQQBnYOs/3WSs6dyX6JnqWzZ7JbceulU=";
            address = "10.10.0.1/24"; # Server address
            # No endpoint - this is the VPN server
          };
        };

        nimbus = {
          user = "toph";
          ip = "10.2.2.2";
          isServer = true;
          isMinimal = true;
          mounts.store = true;
        };

        zebes = {
          user = "toph";
          ip = "10.3.3.3";
          isServer = true;
          isMinimal = true;
          mounts = {
            repo = true;
            tank = true;
          };
        };

        # ── VPN Only ──
        gojo = {
          enable = false; # Do not build host, only VPN config
          vpn = {
            publicKey = "9vgWTiGy9lwjXT6/hqxXNodw4jdhZPVRpbwTIWAxDWg=";
            address = "10.10.0.8/32";
            endpoint = wgEndpoint;
          };
        };

        husky = {
          enable = false; # Do not build host, only VPN config
          vpn = {
            publicKey = "n9EbRKf4syovfi3lnTJ7NCuywLh1IuHL7XX+wK3drUg=";
            address = "10.10.0.10/32";
            endpoint = wgEndpoint;
          };
        };
      };
    };
}
