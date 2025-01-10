{ pkgs, ... }:
{

  dconf = {
    enable = true;
    settings."org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = with pkgs.gnomeExtensions; [
        appindicator.extensionUuid
        blur-my-shell.extensionUuid
        dash-to-panel.extensionUuid
        tiling-shell.extensionUuid
      ];
    };
  };

}
