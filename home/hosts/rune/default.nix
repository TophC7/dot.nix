{
  flakeRoot,
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    ## Rune Specific Imports ##
    (lib.fs.scanPaths ./.)

    ## Additional Imports ##
    (map (lib.fs.relativeTo flakeRoot) [
      "modules/home/common/chromium.nix"
      "modules/home/common/claude.nix"
      "modules/home/common/gaming"
      "modules/home/common/vscode.nix"
      "modules/home/common/xdg.nix"
      "modules/home/common/zen.nix"
    ])
  ];

  services.easyeffects = {
    enable = true;
  };

  ## Packages with no needed configs ##
  home.packages = with pkgs; [
    ## Media ##
    ffmpeg_8-full
    spotify
    gpu-screen-recorder-gtk

    ## Social ##
    telegram-desktop
    vesktop

    journey

    ## Tools ##
    bitwarden-desktop
    inspector
    remmina
    solaar
    vial # KB setup

    # Web Dev
    gh
  ];
}
