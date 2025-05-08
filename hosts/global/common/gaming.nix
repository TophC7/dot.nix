{
  pkgs,
  lib,
  config,
  ...
}:
{
  hardware.xone.enable = true; # xbox controller

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
              libpng
              libpulseaudio
              libvorbis
              libkrb5
              keyutils
              gperftools
              gamemode
              ;
          });
      };
      extraCompatPackages = [ pkgs.unstable.proton-ge-bin ];
      gamescopeSession.enable = true;
    };
    #gamescope launch args set dynamically in home/<user>/common/optional/gaming
    gamescope = {
      enable = true;
      capSysNice = true;
    };
    # to run steam games in game mode, add the following to the game's properties from within steam
    # gamemoderun %command%
    gamemode = {
      enable = true;
      settings = {
        #see gamemode man page for settings info
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
