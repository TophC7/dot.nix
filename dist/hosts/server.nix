{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  hostSpec = config.hostSpec;
  username = "nixos";
  user = config.secretsSpec.users.${username};

  calamares-nixos-autostart = pkgs.makeAutostartItem {
    name = "io.calamares.calamares";
    package = pkgs.calamares-nixos;
  };
in
{
  imports = [
    "${inputs.dot-nix}/hosts/global/core"
    "${inputs.dot-nix}/hosts/global/common/plymouth.nix" # fancy boot screen
  ];

  hostSpec = {
    hostName = "nixos";
    username = username;
    hashedPassword = user.hashedPassword;
    email = user.email;
    handle = user.handle;
    userFullName = user.fullName;
    isServer = false;
    isMinimal = false;
  };

  console = {
    enable = true;
    keyMap = "us";
  };

  home-manager = lib.mkForce {
    extraSpecialArgs = {
      inherit pkgs inputs;
      inherit (config) secretsSpec hostSpec;
    };
    users = {
      root.home.stateVersion = "24.05"; # Avoid error
      ${username} = {
        imports = [
          (import "${inputs.dot-nix}/home/global/core" {
            inherit
              config
              hostSpec
              inputs
              lib
              pkgs
              ;
          })
        ];
      };
    };
  };
}
