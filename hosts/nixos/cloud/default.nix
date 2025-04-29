###############################################################
#
#  Cloud - LXC Container
#  NixOS container, Ryzen 5 5600G (4th Cores), 4GB/4GB RAM/SWAP
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
  firewall = config.secretsSpec.firewall.cloud;
in
{
  imports = lib.flatten [

    ## Cloud Only ##
    ./config

    ## Hardware ##
    ./hardware.nix

    (map lib.custom.relativeToRoot [
      ## Required Configs ##
      "hosts/common/core"

      ## Optional Configs ##
      "hosts/common/optional/acme"
      "hosts/common/optional/docker.nix"

      ## Host user ##
      "hosts/users/${username}" # Not the best solution but I always have one user so ¯\_(ツ)_/¯
    ])
  ];

  ## Host Specifications ##
  hostSpec = {
    hostName = "cloud";
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
      allowedUDPPorts = firewall.allowedUDPPorts;
    };
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [
    apprise
    lazydocker
    mergerfs
    snapraid
  ];

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
