###############################################################
#
#  Caenus - Oracle VPS
#  NixOS VPS, ____, ____
#
#  Public IP
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
  user = config.secretsSpec.users.${username};
  firewall = config.secretsSpec.firewall.caenus;
in
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

  ## Host Specifications ##
  hostSpec = {
    hostName = "caenus";
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
    firewall.allowedTCPPorts = firewall.allowedTCPPorts;
    firewall.allowedUDPPorts = firewall.allowedUDPPorts;
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [
    lazydocker
  ];

  environment.variables = {
    FLAKE = "${config.hostSpec.home}/git/dot.nix";
  };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
