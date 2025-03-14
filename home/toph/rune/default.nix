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

    ## Host-specific Optional Configs ##
    ../common/optional/browsers
    ../common/optional/desktops
    ../common/optional/development
    ../common/optional/gaming
    ../common/optional/xdg.nix # file associations

    ## Home-specific Configs ##
    ./desktop
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
      vesktop

      ## Tools ##
      bitwarden-desktop
      inspector
      remmina
      wezterm
      vial # KB setup

      ## Productivity ##
      gimp
      inkscape
      ;
  };

  # home.file = {
  #   "run-mac.sh".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.macos-ventura-image.runScript}";
  # };
}
