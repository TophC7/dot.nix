###############################################################
#
#  Barebones LXC Container for Proxmox
#
#  This is a special host for LXC installations in Proxmox.
#  Has the bare-bones configuration needed to then setup the wanted new host config
#
###############################################################

{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    ## Hardware ##
    ./hardware.nix

    (map lib.custom.relativeToRoot [
      ## Required Configs ##
      "hosts/global/core"
    ])
  ];

  networking = {
    enableIPv6 = false;
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
