# Hyprpaper is used to set the wallpaper on the system
{
  pkgs,
  config,
  ...
}:
{
  # The wallpaper is set by stylix
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      splash_offset = 2.0;
    };
  };

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "${pkgs.hyprpaper}/bin/hyprpaper"
    ];
  };
}
