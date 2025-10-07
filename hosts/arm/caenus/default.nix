###############################################################
#
#  Caenus - Oracle VPS
#  NixOS VPS,  4vCPU, 24Ggb RAM, 200GB
#
#  Public IP
#
###############################################################

{
  config,
  host,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    ## Caenus Only ##
    ./config

    ## Hardware ##
    ./hardware.nix

    (map lib.custom.relativeToRoot [
      ## Required Configs ##
      "hosts/global/core"

      ## Optional Configs ##
      "hosts/global/common/docker.nix"
    ])
  ];

  networking = {
    enableIPv6 = false;
    firewall = host.network.firewall;
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
