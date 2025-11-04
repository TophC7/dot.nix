{
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    ## Common Imports ##
    (map lib.custom.relativeToRoot [
      "home/global/common/gaming"
      "home/global/common/vscode.nix"
      "home/global/common/xdg.nix"
      "home/global/common/zen.nix"
    ])

    ## Haze Specific ##
    ./config
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
