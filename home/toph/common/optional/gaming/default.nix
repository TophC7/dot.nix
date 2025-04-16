# This module just provides a customized .desktop file with gamescope args dynamically created based on the
# host's monitors configuration
{
  pkgs,
  config,
  lib,
  ...
}:

let

  path = lib.custom.relativeToRoot "pkgs/common/citron-emu/package.nix";
  citron-emu = pkgs.callPackage path { inherit pkgs; };

  monitor = lib.head (lib.filter (m: m.primary) config.monitors);
  steam-session =
    let
      gamescope = lib.concatStringsSep " " [
        (lib.getExe pkgs.gamescope)
        "--rt"
        "--output-width ${toString monitor.width}"
        "--output-height ${toString monitor.height}"
        "--framerate-limit ${toString monitor.refreshRate}"
        "--prefer-output ${monitor.name}"
        "--adaptive-sync"
        "--expose-wayland"
        "--backend wayland"
        "--force-grab-cursor"
        "--steam"
        # "--hdr-enabled"
      ];
      steam = lib.concatStringsSep " " [
        "steam"
        #"steam://open/bigpicture"
        "-forcedesktopscaling ${toString monitor.scale}"
        "-nofriendsui"
        "-noschatui"
      ];
    in
    pkgs.writeTextDir "share/applications/steam-session.desktop" ''
      [Desktop Entry]
      Name=Steam Session
      Comment=Steam with Gamescope
      Exec=${gamescope} -- ${steam}
      Icon=steam
      Type=Application
      Categories=Network;FileTransfer;Game;
      MimeType=x-scheme-handler/steam;x-scheme-handler/steamlink;
      PrefersNonDefaultGPU = true;
    '';
in
{
  home.packages = with pkgs; [
    citron-emu
    prismlauncher
    ryubing
    steam-session
    # modrinth-app
    (lutris.override {
      extraLibraries = pkgs: [
        # List library dependencies here
      ];
      extraPkgs = pkgs: [
        # List package dependencies here
      ];
    })
  ];
}
