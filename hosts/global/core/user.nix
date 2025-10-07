# User config applicable only to nixos
{
  config,
  host,
  inputs,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  user = host.user;
  # Get user-specific secrets if they exist
  userSecrets = secrets.users.${user.name} or { };
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  isMinimal = host.isMinimal;
in
{
  users.groups = {
    ryot = {
      gid = 1004;
      members = [ user.name ];
    };
  };

  users.mutableUsers = false;
  users.users.${user.name} = {
    isNormalUser = true;
    createHome = true;
    description = "Admin";
    homeMode = "750";
    hashedPassword = userSecrets.hashedPassword;
    uid = 1000;
    group = "ryot";
    shell = user.shell or pkgs.fish;
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
    openssh.authorizedKeys.keys = userSecrets.ssh.publicKeys or [ ];
  };

  # Special sudo config for user
  security.sudo.extraRules = [
    {
      users = [ user.name ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  programs.git.enable = true;

  users.users.root = {
    shell = pkgs.bash;
    hashedPassword = lib.mkForce userSecrets.hashedPassword;
    openssh.authorizedKeys.keys = userSecrets.ssh.publicKeys or [ ];
  };
}
// lib.optionalAttrs (inputs ? "home-manager") {
  # Set up home-manager for the configured user
  home-manager = {
    extraSpecialArgs = {
      inherit
        pkgs
        inputs
        host
        secrets
        ;
      # Don't pass lib - let home-manager use its own extended lib with hm namespace
    };
    users = {
      root.home.stateVersion = "24.05"; # Avoid error
      ${user.name} = {
        imports = [
          (
            { config, ... }:
            import
              (
                if isMinimal then
                  lib.custom.relativeToRoot "home/global/core"
                else
                  lib.custom.relativeToRoot "home/users/${user.name}"
              )
              {
                inherit
                  config
                  host
                  inputs
                  lib
                  pkgs
                  secrets
                  ;
              }
          )
        ];
      };
    };
  };
}
