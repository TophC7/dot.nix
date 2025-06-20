{
  pkgs,
  config,
  lib,
  ...
}:
let
  primaryMonitor = lib.custom.getPrimaryMonitor (config.monitors or [ ]);
  WIDTH = primaryMonitor.width or 1980;
  HEIGHT = primaryMonitor.height or 1080;
  REFRESH_RATE = primaryMonitor.refreshRate or 60;
  VRR = primaryMonitor.vrr or false;
  HDR = primaryMonitor.hdr or false;

  # INFO: Example working commands for running games in steam-session
  ## Rivals ##
  # SteamDeck=1 LD_PRELOAD="" PROTON_ENABLE_NVAPI=1 PROTON_ENABLE_WAYLAND=1 VKD3D_DISABLE_EXTENSIONS=VK_KHR_present_wait gamemoderun %command%  -PSOCompileMode=1 -dx12
  ## Stats Overlay ##
  # gamemoderun mangohud %command%
  ## gamescope-run ##
  # GAMESCOPE_EXTRA_OPTS="--force-grab-cursor"; gamescope-run gamemoderun mangohud %command%

  gamescope-base-script = pkgs.writeShellScript "gamescope-base" ''
    # Session configuration
    export CAP_SYS_NICE="eip"
    export DXVK_HDR="1"
    export ENABLE_GAMESCOPE_WSI="1"
    export ENABLE_HDR_WSI="1"
    export AMD_VULKAN_ICD=RADV
    export RADV_PERFTEST=aco
    export SDL_VIDEODRIVER="wayland"

    # Steam environment variables for better compatibility
    export STEAM_FORCE_DESKTOPUI_SCALING=1
    export STEAM_GAMEPADUI=1
    export STEAM_GAMESCOPE_CLIENT=1

    # Default resolution settings
    WIDTH=${toString WIDTH}
    HEIGHT=${toString HEIGHT}
    REFRESH_RATE=${toString REFRESH_RATE}

    # Build gamescope options
    GAMESCOPE_OPTS="--fade-out-duration 200 -w $WIDTH -h $HEIGHT -r $REFRESH_RATE -f"
    GAMESCOPE_OPTS="$GAMESCOPE_OPTS --expose-wayland --backend sdl --rt --immediate-flips"
    ${lib.optionalString HDR ''GAMESCOPE_OPTS="$GAMESCOPE_OPTS --hdr-enabled --hdr-debug-force-output --hdr-itm-enable"''}
    ${lib.optionalString VRR ''GAMESCOPE_OPTS="$GAMESCOPE_OPTS --adaptive-sync"''}
    # Allow extra options to be passed
    GAMESCOPE_OPTS="$GAMESCOPE_OPTS $GAMESCOPE_EXTRA_OPTS"

    # Execute gamescope with provided command
    exec ${lib.getExe pkgs.gamescope} $GAMESCOPE_OPTS -- "$@"
  '';

  gamescope-run = pkgs.writeShellScriptBin "gamescope-run" ''
    if [ $# -eq 0 ]; then
      echo "Usage: gamescope-run <command> [args...]"
      echo "Examples:"
      echo "  gamescope-run heroic"
      echo "  gamescope-run steam"
      echo "  gamescope-run lutris"
      exit 1
    fi

    exec ${gamescope-base-script} "$@"
  '';

  steam-session-script = pkgs.writeShellScript "steam-session-script" ''
    # Check launch mode parameter
    case "$1" in
      "desktop")
        # Launch Steam in desktop mode within gamescope
        exec ${gamescope-base-script} ${lib.getExe pkgs.steam}
        ;;
      "bigpicture"|*)
        # Default: Launch Steam in Big Picture mode
        exec ${gamescope-base-script} ${lib.getExe pkgs.steam} -tenfoot -steamdeck -gamepadui
        ;;
    esac
  '';
in
{
  imports = lib.custom.scanPaths ./.;

  home.packages = with pkgs; [
    prismlauncher
    steam-run
    heroic
    gamescope-run
    # modrinth-app
  ];

  programs.mangohud = {
    enable = true;
    settings = {
      position = "top-right";
      cpu_stats = true;
      gpu_stats = true;
      fps = true;
      font_size = 12;
      cellpadding_y = -0.070;
      background_alpha = lib.mkForce 0.5;
      alpha = lib.mkForce 0.75;
    };
  };

  xdg.desktopEntries = {
    steam = {
      name = "Steam Desktop (Gamescope)";
      comment = "Steam in Gamescope Session";
      exec = "${steam-session-script} desktop";
      icon = "steam";
      type = "Application";
      terminal = false;
      categories = [ "Game" ];
      actions = {
        desktop = {
          name = "Steam Big Picture (Gamescope)";
          exec = "${steam-session-script} bigpicture";
        };
        regular = {
          name = "Steam Desktop (No Gamescope)";
          exec = "${lib.getExe pkgs.steam}";
        };
      };
    };

    "com.heroicgameslauncher.hgl.desktop" = {
      name = "Heroic Games Launcher (Gamescope)";
      comment = "Heroic in Gamescope Session";
      exec = "${lib.getExe gamescope-run} heroic";
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
  };
}
