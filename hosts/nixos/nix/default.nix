###############################################################
#
#  Nix - LXC Container
#  NixOS container, Ryzen 5 5600G (10 Cores), 12GB/6GB RAM/SWAP
#
###############################################################

# TODO: x2go server for remote access

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

      ## Optional Configs ##

      ## Nix Specific ##
      "hosts/users/${username}" # # Not the best solution but I always have one user so ¯\_(ツ)_/¯
    ])
  ];

  ## Host Specifications ##
  hostSpec = {
    hostName = "nix";
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
  # environment.systemPackages = with pkgs; [
  # ];

  # environment.etc = {
  #   "cloudflared/.keep" = {
  #     text = "This directory is used to store cloudflared configuration files.";
  #   };
  # };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
