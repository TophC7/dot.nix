###############################################################
#
#  Rune - Main Desktop
#  NixOS running on Ryzen 9 7900X3D , Radeon RX 6950 XT, 32GB RAM
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
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    (map lib.custom.relativeToRoot [
      ## Required Configs ##
      "hosts/common/core"

      ## Optional Configs ##
      "hosts/common/optional/audio.nix" # pipewire and cli controls
      "hosts/common/optional/gaming.nix" # steam, gamescope, gamemode, and related hardware
      "hosts/common/optional/gnome.nix" # desktop
      "hosts/common/optional/libvirt.nix" # vm tools
      "hosts/common/optional/nvtop.nix" # GPU monitor (not available in home-manager)
      "hosts/common/optional/plymouth.nix" # fancy boot screen

      ## Misc Inputs ##

      ## Rune Specific ##
      "hosts/users/${username}" # # Not the best solution but I always have one user so ¯\_(ツ)_/¯
    ])
  ];

  ## Host Specifications ##
  hostSpec = {
    hostName = "rune";
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
  };

  ## System-wide packages ##
  environment.systemPackages = with pkgs; [
    asdf-vm
    openssh
    ranger
    sshfs
    wget
  ];

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
