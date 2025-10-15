{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  imports = lib.flatten [
    ## Common Imports ##
    (map lib.custom.relativeToRoot [
      "home/global/common/chromium.nix"
      "home/global/common/claude.nix"
      "home/global/common/gaming"
      "home/global/common/vscode.nix"
      "home/global/common/xdg.nix"
      "home/global/common/zen.nix"
    ])

    ## Rune Specific ##
    ./config
  ];

  ## Packages with no needed configs ##
  home.packages = with pkgs; [
    ## Media ##
    ffmpeg
    spotify
    gpu-screen-recorder-gtk

    ## Social ##
    telegram-desktop
    discord-krisp
    betterdiscordctl
    journey

    ## Tools ##
    bitwarden-desktop
    inspector
    remmina
    solaar
    vial # KB setup

    # Web Dev
    gh

    ## Minecraft ##
    modrinth-app

    ## Development ##
    # jetbrains.idea-ultimate
  ];
}
