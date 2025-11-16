###############################################################
#
#  Rune - Toph's Desktop
#  NixOS running on Ryzen 9 7900X3D , Radeon RX 9070 XT, 32GB RAM
#
###############################################################

{
  config,
  inputs,
  lib,
  pkgs,
  secrets,
  ...
}:
{
  imports = lib.flatten [
    ## Rune Only ##
    inputs.chaotic.nixosModules.default
    ./config

    ## Hardware ##
    ./hardware.nix
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    (map lib.custom.relativeToRoot [
      ## Required Configs ##
      "hosts/global/core"

      ## Optional Configs ##
      "hosts/global/common/audio.nix" # pipewire and cli controls
      "hosts/global/common/adb.nix" # android tools
      "hosts/global/common/bluetooth.nix"
      "hosts/global/common/ddcutil.nix" # ddcutil for monitor controls
      "hosts/global/common/gaming.nix" # steam, gamescope, gamemode, and related hardware
      "hosts/global/common/libvirt.nix" # vm tools
      "hosts/global/common/nvtop.nix" # GPU monitor (not available in home-manager)
      "hosts/global/common/plymouth.nix" # fancy boot screen
      "hosts/global/common/solaar.nix" # Logitech Unifying Receiver support
      "hosts/global/common/waydroid.nix" # Android container
      "hosts/global/common/kb.nix" # Keyboard setup
    ])
  ];

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
  environment.sessionVariables = rec {
    CACHIX_AUTH_TOKEN = secrets.service.cachix.token;
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
