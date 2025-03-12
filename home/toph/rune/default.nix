{ pkgs, config, ... }:
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
      wezterm
      vial # KB setup

      ## Productivity ##
      gimp
      inkscape
      ;
  };

  xdg.desktopEntries = {
    # fleet = {
    #   name = "Fleet";
    #   comment = "Jetbrains Fleet";
    #   exec = "fleet %u";
    #   icon = "${config.home.homeDirectory}/.local/share/JetBrains/Toolbox/apps/fleet/lib/Fleet.png";
    #   type = "Application";
    #   terminal = false;
    #   mimeType = [
    #     "text/plain"
    #     "inode/directory"
    #   ];
    #   categories = [
    #     "Development"
    #     "IDE"
    #   ];
    # };

    win11 = {
      name = "Windows 11";
      comment = "Windows 11 VM";
      exec = "virt-manager --connect qemu:///session --show-domain-console win11";
      icon = "windows95";
      type = "Application";
      terminal = false;
      categories = [
        "System"
        "Application"
      ];
    };
  };
}
