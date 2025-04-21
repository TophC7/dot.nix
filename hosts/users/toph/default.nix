{
  inputs,
  pkgs,
  config,
  lib,
  ...
}:
let
  hostSpec = config.hostSpec;
  username = hostSpec.username;
  homeDir = hostSpec.home;
  pubKeys = lib.filesystem.listFilesRecursive ./keys;
in
{
  users.users.${username} = {
    name = hostSpec.username;
    shell = pkgs.fish; # default shell

    # These get placed into /etc/ssh/authorized_keys.d/<name> on nixos
    openssh.authorizedKeys.keys = lib.lists.forEach pubKeys (key: builtins.readFile key);
  };

  # Create ssh sockets directory for controlpaths when homemanager not loaded (i.e. isMinimal)
  systemd.tmpfiles.rules =
    let
      user = config.users.users.${username}.name;
      group = config.users.users.${username}.group;
    in
    [
      "d ${homeDir}/.ssh 0750 ${user} ${group} -"
    ];

  # No matter what environment we are in we want these tools
  programs.fish.enable = true;
}
# Import the user's personal/home configurations, unless the environment is minimal
// lib.optionalAttrs (inputs ? "home-manager") {
  home-manager = {
    extraSpecialArgs = {
      inherit pkgs inputs;
      hostSpec = config.hostSpec;
    };
    users.${username}.imports = lib.flatten (
      lib.optional (!hostSpec.isMinimal) [
        (
          { config, ... }:
          import (lib.custom.relativeToRoot "home/${username}/${hostSpec.hostName}") {
            inherit
              pkgs
              inputs
              config
              lib
              hostSpec
              ;
          }
        )
      ]
    );
  };
}
