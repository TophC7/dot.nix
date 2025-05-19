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
  user = config.secretsSpec.users.${username};
in
{
  imports = lib.flatten [
    ## Rune Only ##
    # ./config

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
      "hosts/global/common/gnome.nix"
      "hosts/global/common/libvirt.nix" # vm tools
      "hosts/global/common/nvtop.nix" # GPU monitor (not available in home-manager)
      "hosts/global/common/plymouth.nix" # fancy boot screen
      "hosts/global/common/vial.nix" # KB setup
    ])
  ];

  ## Host Specifications ##
  hostSpec = {
    hostName = "rune";
    username = username;
    hashedPassword = user.hashedPassword;
    email = user.email;
    handle = user.handle;
    userFullName = user.fullName;
    isServer = true;
  };

  networking = {
    enableIPv6 = false;
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [
    asdf-vm
  ];

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
