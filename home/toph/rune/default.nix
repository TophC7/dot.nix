{
  pkgs,
  inputs,
  config,
  ...
}:
{
  imports = [
    ## Required Configs ##
    ../common/core # required

    ## Optional Configs ##
    ../common/optional/browsers
    ../common/optional/gnome
    ../common/optional/development
    ../common/optional/gaming
    ../common/optional/xdg.nix

    ## Rune Specific ##
    ./config
  ];

  ## Packages with no needed configs ##
  home.packages = builtins.attrValues {
    inherit (pkgs)
      ## Media ##
      ffmpeg
      spotify
      gpu-screen-recorder-gtk

      ## Social ##
      telegram-desktop
      discord
      betterdiscordctl

      ## Tools ##
      bitwarden-desktop
      inspector
      remmina
      vial # KB setup

      ## Productivity ##
      gimp
      inkscape
      ;
  };
}
