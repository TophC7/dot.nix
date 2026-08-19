{
  config,
  gpu,
  host,
  lib,
  pkgs,
  ...
}:
let
  user = host.user.name;
  homeConfig = config.home-manager.users.${user};
  wayscope = homeConfig.programs.wayscope;
  primaryMonitor = lib.findFirst (
    monitor: monitor.primary
  ) (builtins.head homeConfig.monitors) homeConfig.monitors;
  gnomeConnector = builtins.replaceStrings [ "HDMI-A-" ] [ "HDMI-" ] primaryMonitor.name;
  nativeMode = "${toString primaryMonitor.width}x${toString primaryMonitor.height}@${toString primaryMonitor.refreshRate}.000";
  lowResolution = {
    width = 1280;
    height = 720;
    refreshRate = 30;
  };
  # Mutter exposes CTA 720p30 as 29.972 Hz on this NVIDIA output.
  lowResolutionMode = "${toString lowResolution.width}x${toString lowResolution.height}@29.972";
  lowResolutionOptions = {
    output-width = lowResolution.width;
    output-height = lowResolution.height;
    nested-width = lowResolution.width;
    nested-height = lowResolution.height;
    nested-refresh = lowResolution.refreshRate;
  };
  wayscopeEnvironment = {
    XCURSOR_THEME = homeConfig.home.pointerCursor.name or "Adwaita";
    XCURSOR_PATH = "${homeConfig.home.pointerCursor.package or pkgs.adwaita-icon-theme}/share/icons";
  };

  runtimeDir = "/run/user/${toString config.users.users.${user}.uid}";
  eden = lib.getExe pkgs.eden;
  edenWayscope = lib.getExe wayscope.wrappers.sunshine-eden-720p.wrappedPackage;
  heroicWayscope = lib.getExe wayscope.wrappers.sunshine-heroic-720p.wrappedPackage;
  steamWayscope = lib.getExe wayscope.wrappers.sunshine-steam-720p.wrappedPackage;
  gdctl = lib.getExe' pkgs.mutter "gdctl";
  systemctl = lib.getExe' pkgs.systemd "systemctl";
  systemdRun = lib.getExe' pkgs.systemd "systemd-run";

  sunshineGames = pkgs.writeTextFile {
    name = "sunshine-games";
    destination = "/bin/sunshine-games";
    executable = true;
    text = ''
      #!${lib.getExe pkgs.fish}

      set --global --export XDG_RUNTIME_DIR ${runtimeDir}
      set --global --export DBUS_SESSION_BUS_ADDRESS unix:path=$XDG_RUNTIME_DIR/bus

      switch $argv[1]
        case display-720p-start
          ${gdctl} set --logical-monitor --primary --monitor ${gnomeConnector} --mode ${lowResolutionMode} --scale ${toString primaryMonitor.scale}
        case display-720p-stop display-native-start
          ${gdctl} set --logical-monitor --primary --monitor ${gnomeConnector} --mode ${nativeMode} --scale ${toString primaryMonitor.scale}
        case display-native-stop
          true
        case eden-start
          ${systemdRun} --user --unit sunshine-eden --collect ${edenWayscope}
        case eden-stop
          ${systemctl} --user stop sunshine-eden.service; or true
        case heroic-start
          ${systemdRun} --user --unit sunshine-heroic --collect ${heroicWayscope} --console
        case heroic-stop
          ${systemctl} --user stop sunshine-heroic.service; or true
        case steam-start
          ${systemdRun} --user --unit sunshine-steam --collect ${steamWayscope}
        case steam-stop
          ${systemctl} --user stop sunshine-steam.service; or true
      end
    '';
  };
  sunshineGamesCommand = "${sunshineGames}/bin/sunshine-games";
  mkPrepCmd = command: {
    do = "${sunshineGamesCommand} ${command}-start";
    undo = "${sunshineGamesCommand} ${command}-stop";
  };
  lowResolutionPrepCmd = [ (mkPrepCmd "display-720p") ];
  nativeResolutionPrepCmd = [ (mkPrepCmd "display-native") ];
  mkGamePrepCmd = game: lowResolutionPrepCmd ++ [ (mkPrepCmd game) ];
in
{
  users.users.${user}.extraGroups = [ "uinput" ];

  home-manager.users.${user}.programs.wayscope = {
    profiles = {
      sunshine-eden-720p = {
        options = lowResolutionOptions // {
          backend = "wayland";
        };
        environment = wayscopeEnvironment;
      };
      sunshine-heroic-720p = {
        options = lowResolutionOptions // {
          backend = "wayland";
        };
        environment = wayscopeEnvironment;
        unset = [ "DISPLAY" ];
      };
      sunshine-steam-720p = {
        options = lowResolutionOptions // {
          backend = "wayland";
          steam = true;
        };
        environment = wayscopeEnvironment // {
          STEAM_FORCE_DESKTOPUI_SCALING = "1";
          STEAM_GAMEPADUI = "1";
        };
      };
    };
    wrappers = {
      sunshine-eden-720p = {
        enable = true;
        profile = "sunshine-eden-720p";
        command = "${eden} -platform xcb -qwindowgeometry ${toString lowResolution.width}x${toString lowResolution.height}";
      };
      sunshine-heroic-720p = {
        enable = true;
        profile = "sunshine-heroic-720p";
        package = pkgs.heroic;
      };
      sunshine-steam-720p = {
        enable = true;
        profile = "sunshine-steam-720p";
        command = "${lib.getExe config.programs.steam.package} -bigpicture -tenfoot";
      };
    };
  };

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    package = pkgs.sunshine.override { cudaSupport = true; };

    settings = {
      sunshine_name = "meowl";
      csrf_allowed_origins = "https://meowl:47990,https://meowl.ryot.local:47990,https://10.2.2.142:47990,https://10.2.2.5:47990";
      capture = "kms";
      encoder = "nvenc";
      adapter_name = "/dev/dri/by-path/pci-${gpu.pciAddress}-render";
      av1_mode = "0";
      system_tray = "disabled";
    };

    applications.apps = [
      {
        name = "Desktop";
        image-path = "desktop.png";
        prep-cmd = lowResolutionPrepCmd;
      }
      {
        name = "Remote";
        image-path = "desktop-alt.png";
        prep-cmd = nativeResolutionPrepCmd;
      }
      {
        name = "Steam Big Picture";
        image-path = "steam.png";
        prep-cmd = mkGamePrepCmd "steam";
      }
      {
        name = "Heroic Console";
        image-path = ./heroic.png;
        prep-cmd = mkGamePrepCmd "heroic";
      }
      {
        name = "Eden";
        image-path = ./eden.png;
        prep-cmd = mkGamePrepCmd "eden";
      }
    ];
  };
}
