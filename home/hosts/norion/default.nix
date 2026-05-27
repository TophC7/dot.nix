{
  pkgs,
  lib,
  flakeRoot, 
  inputs,
  ...
}:
{
  imports = lib.flatten [
    ## Norion Specific ##
    (lib.fs.scanPaths ./.)

    ## Common Imports ##
    (map (lib.fs.relativeTo flakeRoot) [
      "modules/home/common/chromium.nix"
      "modules/home/common/agents"
      "modules/home/common/gaming"
      "modules/home/common/vscode.nix"
      "modules/home/common/xdg.nix"
      "modules/home/common/zen.nix"
    ])
  ];

  ## Packages with no needed configs ##
  home.packages = with pkgs; [
    ## Media ##
    ffmpeg_8-full
    spotify

    ## Social ##
    telegram-desktop
    vesktop

    ## Tools ##
    solaar

    ## Development ##
    gh
    inputs.sworm.packages.${host.system}.default
  ];
}
