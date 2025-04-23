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
      "hosts/common/optional/adb.nix" # android tools
      "hosts/common/optional/bluetooth.nix"
      "hosts/common/optional/ddcutil.nix" # ddcutil for monitor controls
      "hosts/common/optional/gaming.nix" # steam, gamescope, gamemode, and related hardware
      # "hosts/common/optional/gnome.nix" # desktop
      "hosts/common/optional/hyprland" # desktop
      "hosts/common/optional/libvirt.nix" # vm tools
      "hosts/common/optional/nvtop.nix" # GPU monitor (not available in home-manager)
      "hosts/common/optional/plymouth.nix" # fancy boot screen
      "hosts/common/optional/vial.nix" # KB setup
      # "hosts/common/optional/ventura.nix" # macos vm

      ## Misc Inputs ##

      ## Rune Specific ##
      "hosts/users/${username}" # # Not the best solution but I always have one user so ¯\_(ツ)_/¯
    ])
  ];

  ## Host Specifications ##
  hostSpec = {
    hostName = "rune";
    username = username;
    password = user.password;
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
