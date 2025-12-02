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
      "modules/home/common/gaming"
      "modules/home/common/vscode.nix"
      "modules/home/common/xdg.nix"
      "modules/home/common/zen.nix"
    ])
  ];

  ## Packages with no needed configs ##
  home.packages = builtins.attrValues {
    inherit (pkgs)
      ## Media ##
      ffmpeg_8-full
      spotify
      gpu-screen-recorder-gtk

      ## Social ##
      telegram-desktop
      vesktop

      ## Tools ##
      bitwarden-desktop
      inspector
      solaar
      ;
  };
}
