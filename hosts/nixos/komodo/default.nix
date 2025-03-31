###############################################################
#
#  Komodo - LXC Container
#  NixOS container, Ryzen 5 5600G (12 Cores), 30GB/2GB RAM/SWAP
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

      ## Optional Configs ##
      "hosts/common/optional/acme"
      "hosts/common/optional/caddy"
      "hosts/common/optional/docker.nix"
      "hosts/common/containers/authentik"
      "hosts/common/containers/komodo"

      ## Komodo Specific ##
      "hosts/users/${username}" # # Not the best solution but I always have one user so ¯\_(ツ)_/¯
    ])
  ];

  ## Host Specifications ##
  hostSpec = {
    hostName = "komodo";
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
    # Container Ports
    firewall = {
      allowedTCPPorts = [
        [REDACTED]
        [REDACTED]
        [REDACTED]
        222 # Forgejo SSH
        [REDACTED]
        [REDACTED]
        [REDACTED]
        [REDACTED]
        [REDACTED]
        8080 # File Browser
        [REDACTED]
        [REDACTED]
        [REDACTED]
        [REDACTED]
        [REDACTED]
      ];

      # Game Server Ports
      allowedTCPPortRanges = [
        {
          [REDACTED]
          [REDACTED]
        }
      ];

      allowedUDPPorts = [
        8089 # Grafana
      ];
    };
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [
    lazydocker
    compose2nix
  ];

  # environment.etc = {
  #   "cloudflared/.keep" = {
  #     text = "This directory is used to store cloudflared configuration files.";
  #   };
  # };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
