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
    # ../common/optional/gnome
    ../common/optional/hyprland
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
      vial # KB setup

      ## Productivity ##
      gimp
      inkscape
      ;
  };

  monitors = [
    {
      name = "DP-3";
      x = 900;
      y = 0;
      width = 3840;
      height = 2160;
      refreshRate = 120;
      primary = true;
      scale = 1.20;
      vrr = 2;
    }
    {
      name = "HDMI-A-2";
      x = 0;
      y = 0;
      width = 1920;
      height = 1080;
      refreshRate = 60;
      primary = false;
      transform = 3;
      scale = 1.20;
    }
  ];

  # home.file = {
  #   "run-mac.sh".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.macos-ventura-image.runScript}";
  # };
}
