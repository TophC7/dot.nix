## NOTE:
## This is only configured for AMD GPUs; Nvidia might require additional configuration.
## For example host (PC) configuration using this module go to home/hosts/rune
{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  primaryMonitor = lib.custom.getPrimaryMonitor (config.monitors or [ ]);
  WIDTH = primaryMonitor.width or 1980;
  HEIGHT = primaryMonitor.height or 1080;
  REFRESH_RATE = primaryMonitor.refreshRate or 60;
  VRR = primaryMonitor.vrr or false;
  HDR = primaryMonitor.hdr or false;

  cursorTheme = config.home.pointerCursor.name or "Adwaita";
  cursorPackage = config.home.pointerCursor.package or pkgs.gnome.adwaita-icon-theme;

  # INFO: Example working commands for running games in steam-session
  ## Rivals ##
  # SteamDeck=1 LD_PRELOAD="" PROTON_ENABLE_NVAPI=1 PROTON_ENABLE_WAYLAND=1 VKD3D_DISABLE_EXTENSIONS=VK_KHR_present_wait gamemoderun %command% -PSOCompileMode=1 -dx12
  ## Stats Overlay ##
  # gamemoderun mangohud %command%

  gamescope-env = ''
    set -x DXVK_HDR 1
    set -x ENABLE_GAMESCOPE_WSI 1
    set -x ENABLE_HDR_WSI 1
    set -x AMD_VULKAN_ICD RADV
    set -x RADV_PERFTEST aco
    set -x SDL_VIDEODRIVER wayland
    set -x XCURSOR_THEME '${cursorTheme}'
    set -x XCURSOR_PATH '${cursorPackage}/share/icons'

    # Wayland specific environment variables
    # set -x PROTON_USE_SDL 1
    set -x PROTON_USE_WAYLAND 1
    set -x PROTON_ENABLE_HDR 1

    # Gamescope display identifier
    set -x GAMESCOPE_WAYLAND_DISPLAY "gamescope-0"

    # Steam specific environment variables 
    set -x STEAM_FORCE_DESKTOPUI_SCALING 1
    set -x STEAM_GAMEPADUI 1
    set -x STEAM_GAMESCOPE_CLIENT 1

    # Lutris specific environment variables
    set -x LUTRIS_SKIP_INIT 1
    set -x DISABLE_LAYER_AMD_SWITCHABLE_GRAPHICS_1 1
    set -x DISABLE_LAYER_NV_OPTIMUS_1 1

  '';

  # Base gamescope options
  gamescope-base-opts =
    [
      "--fade-out-duration"
      "200"
      "-w"
      "${toString WIDTH}"
      "-h"
      "${toString HEIGHT}"
      "-r"
      "${toString REFRESH_RATE}"
      "-f"
      "--backend"
      "sdl"
      "--rt"
      "--immediate-flips"
    ]
    ++ lib.optionals HDR [
      "--hdr-enabled"
      "--hdr-debug-force-output"
      "--hdr-itm-enable"
    ]
    ++ lib.optionals VRR [
      "--adaptive-sync"
    ];

  # Run gamescope with a set working environment
  gamescope-run = pkgs.writeScriptBin "gamescope-run" ''
    #!${lib.getExe pkgs.fish}

    # Check if we're already inside a Gamescope session
    if set -q GAMESCOPE_WAYLAND_DISPLAY
      echo "Already inside Gamescope session ($GAMESCOPE_WAYLAND_DISPLAY), running command directly..."
      # Skip gamescope and run the command directly
      exec $argv
    end

    # Session Environment
    ${gamescope-env}

    # Define and parse arguments using fish's built-in argparse
    argparse -i 'x/extra-args=' -- $argv
    if test $status -ne 0
      exit 1
    end

    # The remaining arguments ($argv) are the command to be run
    if test (count $argv) -eq 0
      echo "Usage: gamescope-run [-x|--extra-args \"<options>\"] <command> [args...]"
      echo ""
      echo "Examples:"
      echo "  gamescope-run heroic"
      echo "  gamescope-run -x \"--fsr-upscaling-sharpness 5\" steam"
      echo "  GAMESCOPE_EXTRA_OPTS=\"--fsr\" gamescope-run steam (legacy)"
      exit 1
    end

    # Combine base args, extra args from CLI, and extra args from env (for legacy)
    set -l final_args ${lib.escapeShellArgs gamescope-base-opts}

    # Add args from -x/--extra-args flag, splitting the string into a list
    if set -q _flag_extra_args
        set -a final_args (string split ' ' -- $_flag_extra_args)
    end

    # For legacy support, add args from GAMESCOPE_EXTRA_OPTS if it exists
    if set -q GAMESCOPE_EXTRA_OPTS
        set -a final_args (string split ' ' -- $GAMESCOPE_EXTRA_OPTS)
    end

    # Show the command being executed
    echo -e "\033[1;36m[gamescope-run]\033[0m Running: \033[1;34m${lib.getExe pkgs.gamescope_git}\033[0m $final_args \033[1;32m--\033[0m $argv"

    # Execute gamescope with the final arguments and the command
    exec ${lib.getExe pkgs.gamescope_git} $final_args -- $argv
  '';

  ## Effectively forces gamescope-run to be the default way to use Steam
  ## Why? Because , .desktops created by Steam would not run under gamescope-run otherwise
  ## !!! do not use 'pkgs.steam', it will not be configured correctly
  steam-wrapper = pkgs.writeScriptBin "steam" ''
    #!${lib.getExe pkgs.fish}
    # This script wraps the original steam command to launch it
    # with gamescope-run in a big picture mode.
    # All arguments passed to this script are forwarded.
    exec ${lib.getExe gamescope-run} -x "-e" ${lib.getExe osConfig.programs.steam.package} -tenfoot $argv
  '';

  ## Ensures that all Lutris game launches go through Gamescope
  ## !!! This breaks the Lutris GUI, so use the overridden .desktop entry for opening Lutris itself
  lutris-wrapper = pkgs.writeScriptBin "lutris" ''
    #!${lib.getExe pkgs.fish}
    # This script wraps the original lutris command to launch it
    # with gamescope-run. All arguments passed to this script are forwarded.
    exec ${lib.getExe gamescope-run} -x "--force-windows-fullscreen" ${lib.getExe pkgs.lutris} $argv
  '';
in
{
  home.packages = with pkgs; [
    steam-run
    steam-wrapper
    gamescope-run
    lutris-wrapper
  ];

  xdg.desktopEntries = {
    steam = {
      name = "Steam";
      comment = "Steam Big Picture in Gamescope Session";
      exec = "${lib.getExe steam-wrapper}";
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
          exec = "${lib.getExe pkgs.steam}";
        };
      };
    };

    "com.heroicgameslauncher.hgl" = {
      name = "Heroic Games Launcher";
      comment = "Heroic in Gamescope Session";
      exec = ''${lib.getExe gamescope-run} -x "--force-windows-fullscreen" ${lib.getExe pkgs.heroic}'';
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
      exec = "${lib.getExe pkgs.lutris} %U";
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
          exec = ''${lib.getExe gamescope-run} -x "--force-windows-fullscreen" ${lib.getExe pkgs.lutris}'';
        };

        broken-exposed = {
          name = "Lutris (Gamescope BROKEN; Exposed Wayland)";
          exec = ''${lib.getExe gamescope-run} -x "--force-windows-fullscreen --expose-wayland" ${lib.getExe pkgs.lutris}'';
        };
      };
    };
  };
}
