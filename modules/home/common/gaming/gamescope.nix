{
  config,
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  baseEnv = {
    XCURSOR_THEME = config.home.pointerCursor.name or "Adwaita";
    XCURSOR_PATH = "${config.home.pointerCursor.package or pkgs.adwaita-icon-theme}/share/icons";
    # Zink: translates OpenGL → Vulkan for better perf on AMD
    MESA_LOADER_DRIVER_OVERRIDE = "zink";
  };

  baseOptions = {
    backend = "wayland";
  };
in
{
  imports = [
    inputs.wayscope.homeManagerModules.wayscope
  ];

  programs.wayscope = {
    enable = true;
    # mix.nix's overlay builds both packages from the host package set, keeping
    # Gamescope and Mesa/RADV on the same glibc.
    gamescope = {
      package = pkgs.gamescope-git;
      wsiPackage = pkgs.gamescope-git.wsi;
    };

    # Monitors come from config.monitors (mix.nix) automatically
    # useSystemMonitors = true; # Auto-detected

    profiles = {
      # Default profile - used when no profile specified
      default = {
        options = baseOptions;
        environment = baseEnv;
      };

      wayland = {
        options = baseOptions;
        environment = baseEnv;
        unset = [ "DISPLAY" ];
      };

      steam = {
        options = baseOptions // {
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

      heroic = {
        enable = true;
        profile = "wayland";
        package = pkgs.heroic;
      };

      heroic-console = {
        enable = true;
        profile = "wayland";
        command = "${lib.getExe pkgs.heroic} --console";
      };
    };
  };

  # Heroic cannot discover Proton builds exposed only through Steam's wrapper.
  xdg.configFile = lib.listToAttrs (
    map (proton: {
      name = "heroic/tools/proton/${proton.name}";
      value.source = "${proton}/bin";
    }) osConfig.programs.steam.extraCompatPackages
  );

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
