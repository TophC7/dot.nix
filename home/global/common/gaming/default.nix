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

  gamescope-env = ''
    set -x CAP_SYS_NICE eip
    set -x DXVK_HDR 1
    set -x ENABLE_GAMESCOPE_WSI 1
    set -x ENABLE_HDR_WSI 1
    set -x AMD_VULKAN_ICD RADV
    set -x RADV_PERFTEST aco
    set -x SDL_VIDEODRIVER wayland
    set -x STEAM_FORCE_DESKTOPUI_SCALING 1
    set -x STEAM_GAMEPADUI 1
    set -x STEAM_GAMESCOPE_CLIENT 1
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
      "--expose-wayland"
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

    # Execute gamescope with the final arguments and the command
    exec ${lib.getExe pkgs.gamescope} $final_args -- $argv
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

  xdg.desktopEntries =
    let
      steamBigPictureCmd = ''${lib.getExe gamescope-run} -x "-e" ${lib.getExe pkgs.steam} -tenfoot -steamdeck -gamepadui'';
      heroicGamescopeCmd = ''${lib.getExe gamescope-run} -x "--force-windows-fullscreen" ${lib.getExe pkgs.heroic}'';
    in
    {
      steam = {
        name = "Steam";
        comment = "Steam Big Picture (Gamescope)";
        exec = steamBigPictureCmd;
        icon = "steam";
        type = "Application";
        terminal = false;
        categories = [ "Game" ];
        actions = {
          bigpicture = {
            name = "Steam Client (No Gamescope)";
            exec = "${lib.getExe pkgs.steam}";
          };
        };
      };

      "com.heroicgameslauncher.hgl.desktop" = {
        name = "Heroic Games Launcher (Gamescope)";
        comment = "Heroic in Gamescope Session";
        exec = heroicGamescopeCmd;
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
