###############################################################
#
#  Haze - Cesar's Desktop
#  NixOS running on Ryzen 5 7600x, Radeon RX 7600, 32GB RAM
#
###############################################################

{
  flakeRoot,
  inputs,
  lib,
  ...
}:
{
  imports = lib.flatten [
    ## Haze Specific Imports ##
    (lib.fs.scanPaths ./.)

    ## Hardware ##
    inputs.chaotic.nixosModules.default
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    ## Additional Configs ##
    (map (lib.fs.relativeTo flakeRoot) [
      "modules/hosts/common/audio.nix" # pipewire and cli controls
      "modules/hosts/common/bluetooth.nix"
      "modules/hosts/common/ddcutil.nix" # ddcutil for monitor controls
      "modules/hosts/common/gaming.nix" # steam, gamescope, gamemode, and related hardware
      "modules/hosts/common/nvtop.nix" # GPU monitor (not available in home-manager)
      "modules/hosts/common/plymouth.nix" # fancy boot screen
      "modules/hosts/common/solaar.nix" # Logitech Unifying Receiver support
    ])
  ];

  networking = {
    enableIPv6 = false;
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
