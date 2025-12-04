###############################################################
#
#  Norion- Psynk's Workstation laptop
#  NixOS running on Ryzen AI 9 HX PRO 370, 64GB RAM
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
    ## Norion Specific Imports ##
    (lib.fs.scanPaths ./.)

    ## Hardware ##
    inputs.chaotic.nixosModules.default
    inputs.hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen5

    ## Additional Configs ##
    (map (lib.fs.relativeTo flakeRoot) [
      "modules/hosts/common/audio.nix"
      "modules/hosts/common/bluetooth.nix"
      "modules/hosts/common/ddcutil.nix"
      "modules/hosts/common/gaming.nix"
      "modules/hosts/common/kb.nix"
      "modules/hosts/common/nvtop.nix"
      "modules/hosts/common/plymouth.nix"
      "modules/hosts/common/solaar.nix"
      "modules/hosts/common/vpn.nix"
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
  system.stateVersion = "25.11";
}

# mangohud gamemoderun PROTON_NO_ESYNC=1 PROTON_NO_FSYNC=1 %command% --nologo --waitforpreload
# alters
# gamemoderun mangohud %command% -windowed
