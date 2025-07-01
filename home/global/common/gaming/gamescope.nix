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
      steam = lib.mkDefault {
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

      heroic = lib.mkDefault {
        enable = true;
        package = pkgs.heroic; # No special package configured by play.nix
        extraOptions = {
          "force-windows-fullscreen" = true;
        };
      };

      lutris = lib.mkDefault {
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

  xdg.desktopEntries = {

    ## Steam and Games ##
    steam = lib.mkDefault {
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
        client = {
          name = "Steam Client (No Gamescope)";
          exec = "${lib.getExe osConfig.programs.steam.package}";
        };
        steamdeck = {
          name = "Steam Deck (Gamescope)";
          exec = "${lib.getExe config.play.wrappers.steam.wrappedPackage} -steamdeck";
        };
      };
    };

    ## Other Launchers ##
    "com.heroicgameslauncher.hgl" = lib.mkDefault {
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

    "net.lutris.Lutris" = lib.mkDefault {
      name = "Lutris";
      comment = "Video Game Preservation Platform";
      exec = "${lib.getExe osConfig.play.lutris.package} %U";
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
          exec = ''${lib.getExe config.play.gamescoperun.package} -x "--force-windows-fullscreen --expose-wayland" ${lib.getExe osConfig.play.lutris.package}'';
        };
      };
    };
  };
}
