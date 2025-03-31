###############################################################
#
#  Prozy - LXC Container
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
      "hosts/common/optional/containers/cloudflared.nix"

      ## Proxy Specific ##
      "hosts/users/${username}" # # Not the best solution but I always have one user so ¯\_(ツ)_/¯
    ])
  ];

  ## Host Specifications ##
  hostSpec = {
    hostName = "proxy";
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
    [REDACTED]
      80 # Caddy
      443 # Caddy
      [REDACTED]
    ];
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
