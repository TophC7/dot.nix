{
  config,
  pkgs,
  ...
}:
{
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
