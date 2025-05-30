###############################################################
#
#  Nix - LXC Container
#  NixOS container, Ryzen 5 5600G (10 Cores), 12GB/6GB RAM/SWAP
#
#  Remote Desktop access, with vscode-server, WIP
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
  user = config.secretsSpec.users.${username};
in
{
  imports = lib.flatten [
    ## Hardware ##
    ./hardware.nix

    (map lib.custom.relativeToRoot [
      ## Required Configs ##
      "hosts/global/core"

      ## Optional Configs ##
    ])
  ];

  ## Host Specifications ##
  hostSpec = {
    hostName = "nix";
    username = username;
    hashedPassword = user.hashedPassword;
    email = user.email;
    handle = user.handle;
    userFullName = user.fullName;
    isServer = true;
  };

  networking = {
    enableIPv6 = false;
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;
  # environment.systemPackages = with pkgs; [
  # ];

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
