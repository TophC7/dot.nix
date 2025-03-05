{ pkgs, ... }:
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

      ## Productivity ##
      gimp
      inkscape
      ;
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [
        "qemu:///session"
        "qemu:///system"
      ];
      uris = [
        "qemu:///session"
        "qemu:///system"
      ];
    };
  };

  xdg.desktopEntries = {
    win11 = {
      name = "Windows 11";
      comment = "Windows 11 VM";
      exec = "virt-manager --connect qemu:///system --show-domain-console win11-sys";
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
