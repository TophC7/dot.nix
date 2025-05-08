###############################################################
#
#  Proxy - LXC Container
#  NixOS container, Ryzen 5 5600G (3 Cores), 2GB/2GB RAM/SWAP
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
  firewall = config.secretsSpec.firewall.proxy;
in
{
  imports = lib.flatten [
    ## Proxy Only ##
    ./config

    ## Hardware ##
    ./hardware.nix

    (map lib.custom.relativeToRoot [
      ## Required Configs ##
      "hosts/global/core"

      ## Optional Configs ##
      "hosts/global/common/acme"
      "hosts/global/common/docker.nix"

      ## Proxy User ##
      "hosts/users/${username}" # # Not the best solution but I always have one user so ¯\_(ツ)_/¯
    ])
  ];

  ## Host Specifications ##
  hostSpec = {
    hostName = "proxy";
    username = username;
    hashedPassword = user.hashedPassword;
    email = user.email;
    handle = user.handle;
    userFullName = user.fullName;
    isServer = true;
  };

  networking = {
    enableIPv6 = false;
    firewall.allowedTCPPorts = firewall.allowedTCPPorts;
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [
    lazydocker
  ];

  environment.etc = {
    "cloudflared/.keep" = {
      text = "This directory is used to store cloudflared configuration files.";
    };
  };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
