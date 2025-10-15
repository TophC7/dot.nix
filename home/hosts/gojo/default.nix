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

    ## Gojo Specific ##
    ./config
  ];

  ## Packages with no needed configs ##
  home.packages = builtins.attrValues {
    inherit (pkgs)
      ## Media ##
      ffmpeg
      gpu-screen-recorder-gtk
      spotify
      youtube-music

      ## Social ##
      betterdiscordctl
      discord-krisp
      telegram-desktop

      ## Tools ##
      bitwarden-desktop
      inspector
      solaar

      ## Minecraft ##
      # modrinth-app
      # gdlauncher-carbon
      ;
  };
}
