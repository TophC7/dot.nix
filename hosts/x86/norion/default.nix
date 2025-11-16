###############################################################
#
#  Norion- Psynk's Workstation laptop
#  NixOS running on Ryzen AI 9 HX PRO 370, 64GB RAM
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
      "hosts/global/common/gaming.nix" # steam, gamescope, gamemode, and related hardware
      "hosts/global/common/nvtop.nix" # GPU monitor (not available in home-manager)
      # "hosts/global/common/pangolin/olm.nix" # OLM tunnel client
      "hosts/global/common/plymouth.nix" # fancy boot screen
      "hosts/global/common/solaar.nix" # Logitech Unifying Receiver support
      "hosts/global/common/kb.nix" # Keyboard setup
      "hosts/global/common/vpn.nix" # Homelab VPN access
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
  services.olm.enableGnomeExtension = true;
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}

# mangohud gamemoderun PROTON_NO_ESYNC=1 PROTON_NO_FSYNC=1 %command% --nologo --waitforpreload
# alters
# gamemoderun mangohud %command% -windowed
