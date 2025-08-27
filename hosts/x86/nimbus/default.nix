###############################################################
#
#  Nimbus - LXC Container
#  NixOS container, Ryzen 5 5600G (4 Cores), 4GB/4GB RAM/SWAP
#
#  Storage, NFS, Filerun, and Backups
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
  firewall = config.secretsSpec.firewall.nimbus;
in
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
    ])
  ];

  ## Host Specifications ##
  hostSpec = {
    hostName = "nimbus";
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
    firewall = {
      allowedTCPPorts = firewall.allowedTCPPorts;
      allowedUDPPorts = firewall.allowedUDPPorts;
    };
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [
  ];

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
