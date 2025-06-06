###############################################################
#
#  Haze - Cesar's Desktop
#  NixOS running on Ryzen 7 ___ , Radeon RX 6950 XT, 32GB RAM
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
  username = "cesar";
  user = config.secretsSpec.users.${username};
in
{
  imports = lib.flatten [
    ## Haze Only ##
    inputs.chaotic.nixosModules.default
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
      "hosts/global/common/bluetooth.nix"
      "hosts/global/common/ddcutil.nix" # ddcutil for monitor controls
      "hosts/global/common/gaming.nix" # steam, gamescope, gamemode, and related hardware
      "hosts/global/common/gnome.nix"
      "hosts/global/common/nvtop.nix" # GPU monitor (not available in home-manager)
      "hosts/global/common/plymouth.nix" # fancy boot screen
      "hosts/global/common/solaar.nix" # Logitech Unifying Receiver support
    ])
  ];

  ## Host Specifications ##
  hostSpec = {
    hostName = "haze";
    username = username;
    hashedPassword = user.hashedPassword;
    email = user.email;
    handle = user.handle;
    userFullName = user.fullName;
  };

  networking = {
    enableIPv6 = false;
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [
    asdf-vm
  ];

  environment.sessionVariables = {
    AMD_VULKAN_ICD = "RADV";
    RADV_PERFTEST = "aco";
    PROTON_USE_D9VK = 1;
  };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
