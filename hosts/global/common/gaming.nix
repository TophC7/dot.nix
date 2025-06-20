{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let

  # TODO: Automate when I figure out monitors.nix
  WIDTH = 3840;
  HEIGHT = 2160;
  REFRESH_RATE = 120;
  HDR = true;

  gamescope-session-script = pkgs.writeShellScript "gamescope-session-script" ''
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
    # export STEAM_DIRECT_COMPATIBILITY_TOOLS=1

    # Default resolution settings - adjust to your display
    WIDTH=${toString WIDTH}
    HEIGHT=${toString HEIGHT}
    REFRESH_RATE=${toString REFRESH_RATE}

    # Gamescope options
    GAMESCOPE_OPTS="--fade-out-duration 200 -w $WIDTH -h $HEIGHT -r $REFRESH_RATE -f"
    GAMESCOPE_OPTS="$GAMESCOPE_OPTS --expose-wayland --backend sdl"
    GAMESCOPE_OPTS="$GAMESCOPE_OPTS --rt --adaptive-sync --immediate-flips"
    ${
      if HDR then
        ''GAMESCOPE_OPTS="$GAMESCOPE_OPTS --hdr-enabled --hdr-debug-force-output --hdr-itm-enable"''
      else
        ""
    }

    # Launch Steam in Big Picture mode
    ${lib.getExe pkgs.gamescope} $GAMESCOPE_OPTS --steam -- ${lib.getExe pkgs.steam} -tenfoot -steamdeck -gamepadui
  '';

  # INFO: Example working commands for running games in steam-session

  ## Rivals ##
  # SteamDeck=1 LD_PRELOAD="" PROTON_ENABLE_NVAPI=1 PROTON_ENABLE_WAYLAND=1 VKD3D_DISABLE_EXTENSIONS=VK_KHR_present_wait gamemoderun %command% -dx12n

  ## Stats Overlay ##
  # gamemoderun mangohud %command%

  steam-session = pkgs.writeTextDir "share/applications/steam-session.desktop" ''
    [Desktop Entry]
    Name=Steam Session
    Comment=Launch Steam in Gamescope (nested mode)
    Exec=${gamescope-session-script}
    Icon=steam
    Terminal=false
    Type=Application
    Categories=Game;
  '';
in
{

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # AMDgpu tool
  environment.systemPackages = with pkgs; [
    lact
    gamescope
    # gamescope-wsi
    steam-session
  ];

  systemd = {
    packages = with pkgs; [ lact ];
    services.lactd.wantedBy = [ "multi-user.target" ];
  };

  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      protontricks = {
        enable = true;
        package = pkgs.protontricks;
      };

      # PKGs needed for gamescope to work within steam
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
              mangohud
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
