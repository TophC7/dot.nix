###############################################################
#
#  Norion- Psynk's Workstation laptop
#  NixOS running on Ryzen AI 9 HX PRO 370, 64GB RAM
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
in
{
  imports = lib.flatten [
    ## Norion Only ##
    inputs.chaotic.nixosModules.default
    ./config

    ## Hardware ##
    ./hardware.nix
    inputs.hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen5

    (map lib.custom.relativeToRoot [
      ## Required Configs ##
      "hosts/global/core"

      ## Optional Configs ##
      "hosts/global/common/audio.nix" # pipewire and cli controls
      "hosts/global/common/bluetooth.nix"
      "hosts/global/common/ddcutil.nix" # ddcutil for monitor controls
      "hosts/global/common/gnome.nix"
      "hosts/global/common/nvtop.nix" # GPU monitor (not available in home-manager)
      # "hosts/global/common/pangolin/olm.nix" # OLM tunnel client
      "hosts/global/common/plymouth.nix" # fancy boot screen
      "hosts/global/common/solaar.nix" # Logitech Unifying Receiver support
      "hosts/global/common/vial.nix" # KB setup
      "hosts/global/common/vpn.nix" # Homelab VPN access
    ])
  ];

  ## Host Specifications ##
  hostSpec = {
    hostName = "norion";
    username = username;
    hashedPassword = user.hashedPassword;
    email = user.email;
    handle = user.handle;
    userFullName = user.fullName;
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
      machine psynk-private.cachix.org password ${config.secretsSpec.api.cachix}
    '';
  };

  ## Environment variables for Cachix authentication ##
  environment.sessionVariables = rec {
    CACHIX_AUTH_TOKEN = config.secretsSpec.api.cachix;
  };

  ## System-wide packages ##
  services.olm.enableGnomeExtension = true;
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
