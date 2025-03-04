# Specifications For Differentiating Hosts
{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.hostSpec = {
    username = lib.mkOption {
      type = lib.types.str;
      description = "The username of the host";
    };
    password = lib.mkOption {
      type = lib.types.str;
      description = "Password of the host";
    };
    hostName = lib.mkOption {
      type = lib.types.str;
      description = "The hostname of the host";
    };
    email = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "The email of the user";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain of the host";
    };
    userFullName = lib.mkOption {
      type = lib.types.str;
      description = "The full name of the user";
    };
    handle = lib.mkOption {
      type = lib.types.str;
      description = "The handle of the user (eg: github user)";
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
      description = "Used to indicate a minimal host";
    };
    isServer = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Used to indicate a server host";
    };
  };
}
