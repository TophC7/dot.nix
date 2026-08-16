# mix.nix configuration
#
# Declarative host and user definitions using mix.nix library.
# This file is imported as a flake-parts module.
#
# Available in modules via specialArgs:
#   - `host` - Current host spec (host.user, host.isServer, etc.)
#   - `inputs` - All flake inputs
#   - `secrets` - Secrets if configured via mix.secrets
#
_: {
  # No imports; Both hostSpec and secrets are handled by mix.nix directly

  mix =
    let
      userGroups = [
        # Common groups for all users
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
        meowl = {
          user = "toph";
          ip = "10.2.2.5";
          specialArgs.gpus = {
            display = "0000:00:02.0";
            gaming = "0000:01:00.0";
          };
        };

        norion = {
          user = "toph";
          ip = "10.2.2.4";
          mounts = {
            fast = true;
            repo = true;
            store = true;
            tank = true;
          };
          vpn.address = "10.10.0.4/32";
        };

        rune = {
          user = "toph";
          ip = "10.4.4.4";
          mounts = {
            fast = true;
            repo = true;
            store = true;
            tank = true;
          };
        };

        vm = {
          user = "toph";
        };

        # ── x86 Servers ──
        nexus = {
          user = "toph";
          ip = "10.1.1.1";
          isServer = true;
          isMinimal = true;
          mounts.repo = true;
          vpn.address = "10.10.0.1/24"; # Server address
        };

        nimbus = {
          user = "toph";
          ip = "10.2.2.2";
          isServer = true;
          # mix.nix skips home/hosts/<name> when isMinimal is true.
          isMinimal = false;
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
        husky = {
          enable = false; # Do not build host, only VPN config
          vpn.address = "10.10.0.10/32";
        };

        sammy = {
          enable = false; # Do not build host, only VPN config
          vpn.address = "10.10.0.8/32";
        };
      };
    };
}
