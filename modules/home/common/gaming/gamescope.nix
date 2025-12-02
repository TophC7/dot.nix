{
  config,
  osConfig,
  lib,
  pkgs,
  inputs,
  host,
  ...
}:
{
  imports = [
    inputs.play.homeManagerModules.play
  ];

  play = {
    gamescoperun =
      let
        niri = host.desktop == "niri";
      in
      {
        enable = true;
        useGit = true;

        defaultSystemd = false;
        defaultWSI = true;
        defaultHDR = !niri;
        baseOptions = lib.mkIf niri {
          "backend" = "wayland";
        };

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
          "steam" = true;
        };
        environment = {
          STEAM_FORCE_DESKTOPUI_SCALING = 1;
          STEAM_GAMEPADUI = 1;
        };
      };

      # Other game launchers
      heroic = lib.mkDefault {
        enable = true;
        package = pkgs.heroic; # No special package configured by play.nix
        extraOptions = {
          "force-windows-fullscreen" = true;
        };
      };
    };
  };

  # Simple wrapper package for native Steam client
  home.packages = [
    (pkgs.writeShellScriptBin "steam-client" ''
      exec ${lib.getExe osConfig.programs.steam.package} "$@"
    '')
  ];

  xdg.desktopEntries = {
    ## Steam and Games ##
    steam = lib.mkDefault {
      name = "Steam";
      comment = "Steam Big Picture (Gamescope with defaults)";
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
        native = {
          name = "Steam (No Gamescope)";
          exec = "${lib.getExe osConfig.programs.steam.package}";
        };
        kill-processes = {
          name = "Kill Steam/Gamescope Processes";
          exec = "${pkgs.writeShellScript "kill-gaming-processes" ''
            set -e
            ${pkgs.procps}/bin/pkill -f "steam" || true
            ${pkgs.procps}/bin/pkill -f "gamescope" || true  
            ${pkgs.procps}/bin/pkill -f "gamescopereaper" || true
            ${pkgs.libnotify}/bin/notify-send "Gaming Processes" "Killed steam, gamescope, and gamescopereaper processes"
          ''}";
        };
      };
    };

    lemon = {
      name = "Lemon Craft";
      comment = "Minecraft via Steam";
      exec = "${lib.getExe config.play.wrappers.steam.wrappedPackage} steam://rungameid/17657148064751681536";
      icon = "/home/toph/.local/share/PrismLauncher/instances/Lemon Craft/icon.png";
      type = "Application";
      terminal = false;
      categories = [ "Game" ];
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
        native = {
          name = "Heroic (No Gamescope)";
          exec = "${lib.getExe pkgs.heroic}";
        };
      };
    };
  };
}
