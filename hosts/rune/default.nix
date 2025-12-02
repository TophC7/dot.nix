###############################################################
#
#  Rune - Toph's Desktop
#  NixOS running on Ryzen 9 7900X3D , Radeon RX 9070 XT, 32GB RAM
#
###############################################################

{
  flakeRoot,
  inputs,
  lib,
  pkgs,
  secrets,
  ...
}:
{
  imports = lib.flatten [
    ## Rune Specific Imports ##
    (lib.fs.scanPaths ./.)

    ## Hardware ##
    inputs.chaotic.nixosModules.default
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    ## Additional Configs ##
    (map (lib.fs.relativeTo flakeRoot) [
      "modules/hosts/common/adb.nix"
      "modules/hosts/common/audio.nix"
      "modules/hosts/common/bluetooth.nix"
      "modules/hosts/common/ddcutil.nix"
      "modules/hosts/common/gaming.nix"
      "modules/hosts/common/kb.nix"
      "modules/hosts/common/libvirt.nix"
      "modules/hosts/common/nvtop.nix"
      "modules/hosts/common/plymouth.nix"
      "modules/hosts/common/solaar.nix"
      "modules/hosts/common/waydroid.nix"
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
