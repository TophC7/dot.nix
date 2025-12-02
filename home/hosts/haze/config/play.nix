{
  config,
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # Get primary monitor and calculate resolution minus 20 pixels
  primaryMonitor = lib.desktop.monitors.findPrimary config.monitors;
  resX = toString (primaryMonitor.width - 10);
  resY = toString (primaryMonitor.height - 10);
  refresh = toString primaryMonitor.refreshRate;
in
{
  play = {
    wrappers = {
      alters = {
        enable = true;
        command = "${lib.getExe osConfig.programs.steam.package} steam://rungameid/1601570 -tenfoot -nochatui -nofriendsui -ResX=${resX} -ResY=${resY} -refresh=${refresh} -windowed -nomouse";
        extraOptions = {
          "disable-layers" = true;
          "nested-height" = resY;
          "nested-width" = resX;
          "steam" = true;
        };
        environment = {
          __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = 1;
          PROTON_USE_SDL = 1;
          STEAM_FORCE_DESKTOPUI_SCALING = 1;
          STEAM_GAMEPADUI = 1;
          WAYLANDDRV_RAWINPUT = 1;
        };
      };
    };
  };
  # Override default desktop entries to use gamescoperun wrappers/launchers
  home.activation.removeExistingDesktopFiles = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    rm -f "${config.home.homeDirectory}/.local/share/applications/The Alters.desktop"
  '';

  xdg.desktopEntries = {
    "The Alters" = {
      name = "The Alters";
      comment = "A game about life, choices, and the people we meet";
      exec = "${lib.getExe config.play.wrappers.alters.wrappedPackage}";
      icon = "steam_icon_1601570";
      type = "Application";
      terminal = false;
      categories = [ "Game" ];
      actions = {
        regular = {
          name = "The Alters (No Gamescope)";
          exec = "${lib.getExe osConfig.programs.steam.package} steam://rungameid/1601570 -nochatui -nofriendsui -silent -ResX=${resX} -ResY=${resY} -refresh=${refresh} -windowed -nomouse";
        };
      };
    };
  };
}
