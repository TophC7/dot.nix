{
  config,
  pkgs,
  lib,
  ...
}:

# Same idea as package itself, not working might remove

let
  fleet = pkgs.callPackage ../../../../../pkgs/common/fleet/package.nix { };
in
{
  home.packages = [
    fleet
  ];

  xdg.desktopEntries = {
    fleet = {
      name = "Fleet";
      comment = "Jetbrains Fleet";
      exec = "fleet %u";
      icon = "${config.home.homeDirectory}/.local/share/JetBrains/Toolbox/apps/fleet/lib/Fleet.png";
      type = "Application";
      terminal = false;
      mimeType = [
        "text/plain"
        "inode/directory"
        "x-scheme-handler/fleet"
      ];
      categories = [
        "Development"
        "IDE"
      ];
    };
  };
}
