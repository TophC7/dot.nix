# Cliphist - Clipboard history manager for Wayland
{ pkgs, ... }:
{
  home.packages = [ pkgs.cliphist ];

  # Auto-start clipboard history tracking
  systemd.user.services.cliphist = {
    Unit = {
      Description = "Clipboard history manager";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
