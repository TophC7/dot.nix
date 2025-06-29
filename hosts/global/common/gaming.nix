## NOTE:
## This is only configured for AMD GPUs; Nvidia might require additional configuration.
## For example host (PC) configuration using this module go to hosts/x86/rune
{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  environment.systemPackages = with pkgs; [
    lact # AMDgpu tool
    heroic
    gamescope_git
    gamescope-wsi_git
    (pkgs.lutris.override {
      extraPkgs = pkgs: [
        pkgs.wineWowPackages.waylandFull
        pkgs.winetricks
        vulkan-tools
        xterm
      ];
    })
  ];

  systemd = {
    packages = with pkgs; [ lact ];
    services.lactd.wantedBy = [ "multi-user.target" ];
  };

  # Instead of set -x CAP_SYS_NICE eip
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-cpp;
    extraRules = [
      {
        "name" = "gamescope";
        "nice" = -20;
      }
    ];
  };

  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      protontricks = {
        enable = true;
        package = pkgs.protontricks;
      };

      package = pkgs.steam.override {
        extraPkgs =
          pkgs:
          (builtins.attrValues {
            inherit (pkgs.xorg)
              libXcursor
              libXi
              libXinerama
              libXScrnSaver
              ;

            inherit (pkgs.stdenv.cc.cc)
              lib
              ;

            inherit (pkgs)
              gamemode
              gperftools
              keyutils
              libkrb5
              libpng
              libpulseaudio
              libvorbis
              mangohud
              ;
          });
      };
      extraCompatPackages = with pkgs; [
        proton-ge-bin
        proton-ge-custom
        proton-cachyos
      ];
    };

    gamemode = {
      enable = true;
      settings = {
        general = {
          softrealtime = "auto";
          inhibit_screensaver = 1;
          renice = 15;
        };
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 1; # The DRM device number on the system (usually 0), ie. the number in /sys/class/drm/card0/
          amd_performance_level = "high";
        };
        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
        };
      };
    };
  };
}
