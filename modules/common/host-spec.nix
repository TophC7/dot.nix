# Specifications For Differentiating Hosts
{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.hostSpec = {
    hostName = lib.mkOption {
      type = lib.types.str;
      description = "The hostname of the host";
    };

    username = lib.mkOption {
      type = lib.types.str;
      description = "The username for the host's user";
    };

    password = lib.mkOption {
      type = lib.types.str;
      description = "Hashed password for the host's user";
    };

    email = lib.mkOption {
      type = lib.types.str;
      description = "The email of the user";
    };

    handle = lib.mkOption {
      type = lib.types.str;
      description = "The handle of the user (eg: github user)";
    };

    userFullName = lib.mkOption {
      type = lib.types.str;
      description = "The full name of the user";
    };

    home = lib.mkOption {
      type = lib.types.str;
      description = "The home directory of the user";
      default =
        let
          user = config.hostSpec.username;
        in
        if pkgs.stdenv.isLinux then "/home/${user}" else "/Users/${user}";
    };

    isARM = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Used to indicate a host that is aarch64";
    };

    isMinimal = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Used to indicate a minimal configuration host";
    };

    isServer = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Used to indicate a server host";
    };

    desktop = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "Gnome"
          "Hyprland"
        ]
      );
      default = if config.hostSpec.isServer then null else "Gnome";
      description = "Desktop environment (Gnome, Hyprland or null)";
    };

    shell = lib.mkOption {
      type = lib.types.enum [
        pkgs.fish
        pkgs.bash
      ];
      default = pkgs.fish;
      description = "Default shell (pkgs.fish or pkgs.bash)";
    };

    pool = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether it mounts pool from PVE";
    };
  };
}
