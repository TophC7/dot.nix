# User config applicable only to nixos
#
# With mix.nix, basic user creation is handled by mkHost:
#   - isNormalUser, home, group, shell, extraGroups, uid
#
# This module adds gojo.nix-specific extensions:
#   - Custom groups (ryot)
#   - Sudo rules
#   - Secrets (hashedPassword, SSH keys)
#   - Root user config
#
{
  config,
  host,
  lib,
  pkgs,
  secrets ? { },
  ...
}:
let
  user = host.user;
  # Get user-specific secrets if they exist
  userSecrets = secrets.users.${user.name} or { };
in
{
  # Custom group for this setup
  users.groups.ryot = {
    gid = 1004;
    members = [ user.name ];
  };

  users.mutableUsers = false;

  # Extend user created by mix.nix with secrets and extra settings
  users.users.${user.name} = {
    createHome = true;
    description = "Admin";
    homeMode = "750";
    hashedPassword = userSecrets.hashedPassword or null;
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
    hashedPassword = lib.mkForce (userSecrets.hashedPassword or null);
    openssh.authorizedKeys.keys = userSecrets.ssh.publicKeys or [ ];
  };
}
