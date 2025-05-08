# User config applicable only to nixos
{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  hostSpec = config.hostSpec;
  username = hostSpec.username;
  # Get user-specific secrets if they exist
  user = config.secretsSpec.users.${username} or { };
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  isMinimal = hostSpec.isMinimal or false;
in
{
  users.groups = {
    ryot = lib.mkIf (!isMinimal) {
      gid = 1004;
      members = [ username ];
    };
  };

  users.mutableUsers = false;
  users.users.${username} = {
    home = hostSpec.home;
    isNormalUser = true;
    createHome = true;
    description = "Admin";
    homeMode = "750";
    hashedPassword = user.hashedPassword or hostSpec.hashedPassword;
    uid = 1000;
    group = if !isMinimal then "ryot" else "users";
    shell = hostSpec.shell or pkgs.fish;
    extraGroups = lib.flatten [
      "wheel"
      (ifTheyExist [
        "adbusers"
        "audio"
        "docker"
        "gamemode"
        "git"
        "libvirtd"
        "networkmanager"
        "video"
      ])
    ];
    openssh.authorizedKeys.keys = builtins.attrValues config.secretsSpec.ssh.publicKeys or [ ];
  };

  # Special sudo config for user
  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # No matter what environment we are in we want these tools for root, and the user(s)
  programs.git.enable = true;

  # root's ssh key are mainly used for remote deployment, borg, and some other specific ops
  users.users.root = {
    shell = pkgs.bash;
    hashedPassword = lib.mkForce hostSpec.hashedPassword;
    openssh.authorizedKeys.keys = builtins.attrValues config.secretsSpec.ssh.publicKeys or [ ];
  };
}
// lib.optionalAttrs (inputs ? "home-manager") {
  # Setup root home?
  home-manager.users.root = lib.optionalAttrs (!isMinimal) {
    home.stateVersion = "24.05"; # Avoid error
  };

  # Set up home-manager for the configured user
  home-manager = {
    extraSpecialArgs = {
      inherit pkgs inputs;
      inherit (config) secretsSpec hostSpec;
    };
    users.${username} = lib.optionalAttrs (!isMinimal) {
      imports = [
        (
          { config, ... }:
          import (lib.custom.relativeToRoot "home/${username}/${hostSpec.hostName}") {
            inherit
              config
              hostSpec
              inputs
              lib
              pkgs
              ;
          }
        )
      ];
    };
  };
}
