###############################################################
#
#  Barebones LXC Container for Proxmox
#
#  This is a special host for LXC installations in Proxmox.
#  Has the barebones configuration needed to then setup the wanted new host config
#
###############################################################

{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  username = "toph";
in
{
  imports = lib.flatten [
    ## Hardware ##
    ./hardware.nix

    (map lib.custom.relativeToRoot [
      ## Required Configs ##
      "hosts/common/core"

      ## Proxy Specific ##
      "hosts/users/${username}" # # Not the best solution but I always have one user so ¯\_(ツ)_/¯
    ])
  ];

  ## Host Specifications ##
  hostSpec = {
    hostName = "lxc";
    username = username;
    handle = "tophC7";
    password = "[REDACTED]";
    [REDACTED];
    email = "[REDACTED]";
    userFullName = "[REDACTED]";
    isARM = false;
  };

  networking = {
    enableIPv6 = false;
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [
    lazydocker
  ];

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
