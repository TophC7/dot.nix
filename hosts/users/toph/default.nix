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
  _shell = hostSpec.shell;
  pubKeys = builtins.attrValues config.secretsSpec.ssh.publicKeys;
in
{
  users.users.${username} = {
    name = hostSpec.username;
    shell = _shell;
    # These get placed into /etc/ssh/authorized_keys.d/<name> on nixos
    openssh.authorizedKeys.keys = pubKeys;
  };

  # Create ssh directory when homemanager is not loaded
  systemd.tmpfiles.rules =
    let
      user = config.users.users.${username}.name;
      group = config.users.users.${username}.group;
    in
    [
      "d ${homeDir}/.ssh 0750 ${user} ${group} -"
    ];

  programs.fish.enable = true;
}
# Import the user's personal/home configurations, unless the environment is minimal
// lib.optionalAttrs (inputs ? "home-manager") {
  home-manager = {
    extraSpecialArgs = {
      inherit pkgs inputs;
      inherit (config) secretsSpec hostSpec;
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
