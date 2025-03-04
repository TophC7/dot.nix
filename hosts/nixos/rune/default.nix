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
  runtimeLibs = with pkgs.stable; [
    ## native versions
    glfw3-minecraft
    openal

    ## openal
    alsa-lib
    libjack2
    libpulseaudio
    pipewire

    ## glfw
    libGL
    xorg.libX11
    xorg.libXcursor
    xorg.libXext
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libXxf86vm

    udev # oshi

    vulkan-loader # VulkanMod's lwjgl

    freetype
    fontconfig
    flite
  ];
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

  ## Boot ##
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        # When using plymouth, initrd can expand by a lot each time, so limit how many we keep around
        configurationLimit = lib.mkDefault 10;
      };
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    initrd = {
      systemd.enable = true;
      verbose = false;
    };
  };

  ## System-wide packages ##
  environment.systemPackages = with pkgs; [
    asdf-vm
    openssh
    ranger
    sshfs
    wget

    # REMOVE: Same as below
    glfw3-minecraft
    libglvnd
  ];

  programs.nix-ld.libraries = runtimeLibs;

  # FIXME: Remove this in favor of dirEnv
  ## Libs for Minecraft ##
  environment.variables = {
    LD_LIBRARY_PATH = lib.makeLibraryPath runtimeLibs;
  };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
