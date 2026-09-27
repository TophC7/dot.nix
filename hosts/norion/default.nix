###############################################################
#
#  Norion- Psynk's Workstation laptop
#  NixOS running on Ryzen AI 9 HX PRO 370, 64GB RAM
#
###############################################################

{
  inputs,
  lib,
  pkgs,
  secrets,
  ...
}:
{
  imports = lib.flatten [
    ## Norion Specific Imports ##
    ./hardware.nix
    ./config

    ## Hardware ##
    inputs.hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen6

    ## Additional Configs ##
    (lib.features [
      "audio"
      "bluetooth"
      "clamav"
      "ddcutil"
      "docker"
      "gaming"
      "kb"
      "nvtop"
      "plymouth"
      "solaar"
      "vpn"
      "chromium"
      "agents"
      "vscode"
      "xdg"
      "zen"
      "sworm"
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
  environment.sessionVariables = {
    CACHIX_AUTH_TOKEN = secrets.service.cachix.token;
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}

# mangohud gamemoderun PROTON_NO_ESYNC=1 PROTON_NO_FSYNC=1 %command% --nologo --waitforpreload
# alters
# gamemoderun mangohud %command% -windowed
