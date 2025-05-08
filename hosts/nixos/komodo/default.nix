###############################################################
#
#  Komodo - LXC Container
#  NixOS container, Ryzen 5 5600G (12 Cores), 30GB/2GB RAM/SWAP
#
###############################################################

{
  lib,
  config,
  pkgs,
  ...
}:
let
  username = "toph";
  user = config.secretsSpec.users.${username};
  firewall = config.secretsSpec.firewall.komodo;
in
{
  imports = lib.flatten [
    ## Komodo Only ##
    ./config

    ## Hardware ##
    ./hardware.nix

    (map lib.custom.relativeToRoot [
      ## Required Configs ##
      "hosts/global/core"

      ## Optional Configs ##
      "hosts/global/common/acme"
      "hosts/global/common/docker.nix"
    ])
  ];

  ## Host Specifications ##
  hostSpec = {
    hostName = "komodo";
    username = username;
    hashedPassword = user.hashedPassword;
    email = user.email;
    handle = user.handle;
    userFullName = user.fullName;
    isServer = true;
  };

  networking = {
    enableIPv6 = false;
    firewall = {
      allowedTCPPorts = firewall.allowedTCPPorts;
      allowedTCPPortRanges = firewall.allowedTCPPortRanges;
      allowedUDPPorts = firewall.allowedUDPPorts;
    };
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [
    lazydocker
    compose2nix
  ];

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
