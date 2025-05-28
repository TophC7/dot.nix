{
  pkgs,
  lib,
  config,
  ...
}:
{
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  programs = {
    steam = {
      enable = true;
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
              gamescope # !!!: DO NOT ADD GAMESCOPE ANYWHERE ELSE IN CONFIG, IT WILL BREAK!
              gperftools
              keyutils
              libkrb5
              libpng
              libpulseaudio
              libvorbis
              ;
          });
      };
      extraCompatPackages = [ pkgs.unstable.proton-ge-bin ];
      gamescopeSession.enable = true;
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

# gamescope --adaptive-sync --backend sdl --expose-wayland --force-grab-cursor --framerate-limit 120 --immediate-flips --output-height 2160 --output-width 3840 --prefer-output DP-1 --rt -- gamemoderun %command%
