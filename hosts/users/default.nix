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
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  users.groups = {
    ryot = {
      gid = 1004;
      members = [ "${hostSpec.username}" ];
    };
  };

  users.mutableUsers = false; # Only allow declarative credentials; Required for password to be set via sops during system activation!
  users.users.${hostSpec.username} = {
    home = "${hostSpec.home}";
    isNormalUser = true;
    createHome = true;
    description = "Admin";
    homeMode = "750";
    password = hostSpec.password;
    uid = 1000;
    group = "ryot";
    extraGroups = lib.flatten [
      "wheel"
      # Some of these groups are defined elsewhere in the system
      # But honestly not sure what runs first so just add them here i guess
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
  };

  # No matter what environment we are in we want these tools for root, and the user(s)
  programs.git.enable = true;

  # root's ssh key are mainly used for remote deployment, borg, and some other specific ops
  users.users.root = {
    shell = pkgs.bash;
    password = lib.mkForce hostSpec.password;
    openssh.authorizedKeys.keys = config.users.users.${hostSpec.username}.openssh.authorizedKeys.keys; # root's ssh keys are mainly used for remote deployment.
  };
}
// lib.optionalAttrs (inputs ? "home-manager") {

  # Setup root home?
  home-manager.users.root = lib.optionalAttrs (!hostSpec.isMinimal) {
    home.stateVersion = "24.05"; # Avoid error
  };
}
