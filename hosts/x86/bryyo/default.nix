###############################################################
#
#  Bryyo - LXC Container
#  NixOS container, Intel N150  (4 Cores), 8GB/2GB RAM/SWAP
#
#  Docker Environment, Komodo
#
###############################################################

# TODO: the actual sock lxc has not yet migrated to bryyo

{
  lib,
  config,
  pkgs,
  ...
}:
let
  username = "toph";
  user = config.secretsSpec.users.${username};
in
{
  imports = lib.flatten [
    ## Bryyo Only ##
    ./config

    ## Hardware ##
    ./hardware.nix

    (map lib.custom.relativeToRoot [
      ## Required Configs ##
      "hosts/global/core"

      ## Optional Configs ##
      "hosts/global/common/docker.nix"
      "hosts/global/common/newt.nix"
    ])
  ];

  ## Host Specifications ##
  hostSpec = {
    hostName = "bryyo";
    username = username;
    hashedPassword = user.hashedPassword;
    email = user.email;
    handle = user.handle;
    userFullName = user.fullName;
    isServer = true;
    isMinimal = true;
  };

  networking = {
    enableIPv6 = false;
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
