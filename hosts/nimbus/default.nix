###############################################################
#
#  Nimbus - NAS
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
      "modules/hosts/common/komodo-periphery.nix"
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

  # Nimbus is the default remote builder for bonk. Keep Nix from starting too
  # many memory-heavy Rust/C++ derivations at once.
  nix.settings = {
    max-jobs = lib.mkDefault 3;
    cores = lib.mkDefault 4;
  };

  # Fast compressed swap absorbs compiler spikes before falling back to the
  # larger on-disk swapfile from hardware.nix.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
    priority = 100;
  };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
