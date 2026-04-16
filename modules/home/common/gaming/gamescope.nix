{
  config,
  osConfig,
  lib,
  pkgs,
  inputs,
  host,
  ...
}:
let
  # Desktop environment detection for HDR support
  niri = host.desktop.niri.enable;
  hyprland = host.desktop.hyprland.enable;
  gnome = host.desktop.gnome.enable;
  allowHDR = !niri && (hyprland || gnome);
  waylandBackend = !gnome;

  baseEnv = {
    XCURSOR_THEME = config.home.pointerCursor.name or "Adwaita";
    XCURSOR_PATH = "${config.home.pointerCursor.package or pkgs.adwaita-icon-theme}/share/icons";
  };

  baseOptions =
    lib.optionalAttrs waylandBackend {
      backend = "wayland";
    }
    // { };
in
{
  imports = [
    inputs.wayscope.homeManagerModules.wayscope
  ];

  programs.wayscope = {
    enable = true;
    useGit = true;

    # Monitors come from config.monitors (mix.nix) automatically
    # useSystemMonitors = true; # Auto-detected

    profiles = {
      # Default profile - used when no profile specified
      default = {
        useHDR = allowHDR;
        useWSI = true;
        options = baseOptions;
        environment = baseEnv;
      };

      hdr = {
        useHDR = true;
        useWSI = true;
        options = baseOptions;
        environment = baseEnv;
      };

      auto-hdr = {
        useHDR = true;
        useWSI = false;
        options = {
          backend = "sdl";
          hdr-itm-enabled = true;
        };
        environment = baseEnv;
      };

      wayland = {
        useHDR = allowHDR;
        useWSI = true;
        unset = [ "DISPLAY" ];
      };

      # Zink: translates OpenGL → Vulkan for better perf on AMD
      minecraft = {
        useHDR = allowHDR;
        useWSI = true;
        options = baseOptions;
        environment = baseEnv // {
          MESA_LOADER_DRIVER_OVERRIDE = "zink";
        };
        unset = [ "DISPLAY" ];
      };

      steam = {
        useHDR = allowHDR;
        useWSI = true;
        options = baseOptions // {
          steam = true;
        };
        environment = baseEnv // {
          STEAM_FORCE_DESKTOPUI_SCALING = "1";
          STEAM_GAMEPADUI = "1";
        };
      };

      steam-auto-hdr = {
        useHDR = true;
        useWSI = true;
        options = {
          backend = "sdl";
          hdr-itm-enabled = true;
          steam = true;
        };
        environment = baseEnv // {
          STEAM_FORCE_DESKTOPUI_SCALING = "1";
          STEAM_GAMEPADUI = "1";
        };
      };
    };

    wrappers = {
      steam-wayscope = {
        enable = true;
        profile = "steam";
        command = "${lib.getExe osConfig.programs.steam.package} -bigpicture -tenfoot";
      };

      steam-auto-hdr = {
        enable = true;
        profile = "steam-auto-hdr";
        command = "${lib.getExe osConfig.programs.steam.package} -bigpicture -tenfoot";
      };

      heroic = {
        enable = true;
        profile = "auto-hdr";
        package = pkgs.heroic;
      };
    };
  };

  xdg.desktopEntries = {
    ## Steam and Games ##
    steam = lib.mkDefault {
      name = "Steam";
      comment = "Steam Client";
      exec = "${lib.getExe osConfig.programs.steam.package}";
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
        gamescope = {
          name = "Steam Big Picture (Wayscope Profile)";
          exec = "${lib.getExe config.programs.wayscope.wrappers.steam-wayscope.wrappedPackage}";
        };
        gamescope-auto-hdr = {
          name = "Steam Big Picture (Wayscope Profile)";
          exec = "${lib.getExe config.programs.wayscope.wrappers.steam-auto-hdr.wrappedPackage}";
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
      exec = "${lib.getExe config.programs.wayscope.wrappers.steam-wayscope.wrappedPackage} steam://rungameid/17657148064751681536";
      icon = "/home/toph/.local/share/PrismLauncher/instances/Lemon Craft/icon.png";
      type = "Application";
      terminal = false;
      categories = [ "Game" ];
    };

    ## Other Launchers ##
    "com.heroicgameslauncher.hgl" = lib.mkDefault {
      name = "Heroic Games Launcher";
      comment = "Heroic in Gamescope Session";
      exec = "${lib.getExe config.programs.wayscope.wrappers.heroic.wrappedPackage}";
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
