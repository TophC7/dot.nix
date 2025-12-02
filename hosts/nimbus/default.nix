###############################################################
#
#  Nimbus - LXC Container
#  NixOS running on Ryzen 7 5700X, 32GB RAM
#
#  Storage (ZFS), NFS, Filerun, and Backups
#
###############################################################

{
  flakeRoot,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    ## Nimbus Specific Imports ##
    (lib.fs.scanPaths ./.)

    ## Hardware ##
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    ## Additional Configs ##
    (map (lib.fs.relativeTo flakeRoot) [
      "modules/hosts/common/docker.nix"
      "modules/hosts/common/pangolin/newt.nix"
    ])
  ];

  networking = {
    enableIPv6 = false;
    firewall = {
      allowedTCPPorts = [
        111 # rpcbind
        2049 # NFSv4
        4488 # nix-serve
        10048 # mountd
      ];
      allowedUDPPorts = [
        111 # rpcbind
        2049 # NFSv4
        10048 # mountd
      ];
    };
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
