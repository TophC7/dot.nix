###############################################################
#
#  Nimbus - LXC Container
#  NixOS running on Ryzen 7 5700X, 32GB RAM
#
#  Storage (ZFS), NFS, Filerun, and Backups
#
###############################################################

{
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    ## Nimbus Only ##
    ./config

    ## Hardware ##
    ./hardware.nix

    (map lib.custom.relativeToRoot [
      ## Required Configs ##
      "hosts/global/core"

      ## Optional Configs ##
      "hosts/global/common/docker.nix"
      "hosts/global/common/pangolin/newt.nix"
    ])
  ];

  networking = {
    enableIPv6 = false;
    firewall = host.network.firewall;
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
