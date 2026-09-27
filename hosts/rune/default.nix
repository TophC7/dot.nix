###############################################################
#
#  Rune - Toph's Desktop
#  NixOS running on Ryzen 9 7900X3D , Radeon RX 9070 XT, 32GB RAM
#
###############################################################

{
  inputs,
  lib,
  pkgs,
  secrets,
  host,
  ...
}:
{
  imports = lib.flatten [
    ## Rune Specific Imports ##
    ./hardware.nix
    ./config

    ## Hardware ##
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    ## Additional Configs ##
    (lib.features [
      "audio"
      "bluetooth"
      "color"
      "ddcutil"
      "docker"
      "gaming"
      "kb"
      "komodo-periphery"
      "libvirt"
      "nvtop"
      "plymouth"
      "solaar"
      "waydroid"
      "chromium"
      "agents"
      "vscode"
      "xdg"
      "zen"
      "sworm"
    ])
  ];

  play.switch2Controllers = {
    enable = true;
    user = host.user.name;
  };

  networking = {
    enableIPv6 = false;
  };

  ## Nix configuration for private cache authentication ##
  nix.settings = {
    # Add private cache substituter only for norion
    substituters = [
      "https://psynk-private.cachix.org"
    ];
    trusted-public-keys = [
      "psynk-private.cachix.org-1:Kv9E2th/8t6kItQHl3hJVgWaaJTcPhvC63XAie2aAz4="
    ];
    # Generate netrc file from secrets for authentication
    netrc-file = pkgs.writeText "netrc" ''
      machine psynk-private.cachix.org password ${secrets.service.cachix.token}
    '';
  };

  ## Environment variables for Cachix authentication ##
  environment.sessionVariables = {
    CACHIX_AUTH_TOKEN = secrets.service.cachix.token;
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
