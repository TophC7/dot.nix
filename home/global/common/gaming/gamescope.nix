{
  config,
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.play.homeManagerModules.play
  ];

  play = {
    monitors = config.monitors; # I use the same module as in play.nix
    gamescoperun = {
      enable = true;
      useGit = true;

      # Extra environment variables
      environment = {
        XCURSOR_THEME = config.home.pointerCursor.name or "Adwaita";
        XCURSOR_PATH = "${config.home.pointerCursor.package or pkgs.adwaita-icon-theme}/share/icons";
      };
    };

    wrappers = {
      steam = {
        enable = true;
        command = "${lib.getExe osConfig.programs.steam.package} -bigpicture -tenfoot";
        extraOptions = {
          "steam" = true; # equivalent to --steam flag
        };
        environment = {
          STEAM_FORCE_DESKTOPUI_SCALING = 1;
          STEAM_GAMEPADUI = 1;
        };
      };

      heroic = {
        enable = true;
        package = pkgs.heroic; # No special package configured by play.nix
        extraOptions = {
          "force-windows-fullscreen" = true;
        };
      };

      lutris = {
        enable = true;
        package = osConfig.play.lutris.package;
        extraOptions = {
          "force-windows-fullscreen" = true;
        };
        environment = {
          LUTRIS_SKIP_INIT = 1;
        };
      };
    };
  };

  # Override default desktop entries to use gamescope wrappers
  xdg.desktopEntries = {
    steam = {
      name = "Steam";
      comment = "Steam Big Picture in Gamescope Session";
      exec = "${lib.getExe config.play.wrappers.steam.wrappedPackage}";
      icon = "steam";
      type = "Application";
      terminal = false;
      categories = [ "Game" ];
      mimeType = [
        "x-scheme-handler/steam"
        "x-scheme-handler/steamlink"
      ];
      settings = {
        StartupNotify = "true";
        StartupWMClass = "Steam";
        PrefersNonDefaultGPU = "true";
        X-KDE-RunOnDiscreteGpu = "true";
        Keywords = "gaming;";
      };
      actions = {
        bigpicture = {
          name = "Steam Client (No Gamescope)";
          exec = "${lib.getExe (config.play.steam.package or pkgs.steam)}";
        };
      };
    };

    "com.heroicgameslauncher.hgl" = {
      name = "Heroic Games Launcher";
      comment = "Heroic in Gamescope Session";
      exec = "${lib.getExe config.play.wrappers.heroic.wrappedPackage}";
      icon = "com.heroicgameslauncher.hgl";
      type = "Application";
      terminal = false;
      categories = [ "Game" ];
      actions = {
        regular = {
          name = "Heroic (No Gamescope)";
          exec = "${lib.getExe pkgs.heroic}";
        };
      };
    };

    "net.lutris.Lutris" = {
      name = "Lutris";
      comment = "Video Game Preservation Platform";
      exec = "${lib.getExe (config.play.lutris.package or pkgs.lutris)} %U";
      icon = "net.lutris.Lutris";
      type = "Application";
      terminal = false;
      categories = [ "Game" ];
      mimeType = [ "x-scheme-handler/lutris" ];
      settings = {
        StartupNotify = "true";
        StartupWMClass = "Lutris";
        Keywords = "gaming;wine;emulator;";
        X-GNOME-UsesNotifications = "true";
      };
      actions = {
        broken = {
          name = "Lutris (Gamescope BROKEN)";
          exec = "${lib.getExe config.play.wrappers.lutris.wrappedPackage}";
        };

        broken-exposed = {
          name = "Lutris (Gamescope BROKEN; Exposed Wayland)";
          exec = ''${lib.getExe config.play.gamescoperun.package} -x "--force-windows-fullscreen --expose-wayland" ${
            lib.getExe (config.play.lutris.package or pkgs.lutris)
          }'';
        };
      };
    };
  };
}
