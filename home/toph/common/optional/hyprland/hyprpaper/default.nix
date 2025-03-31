# Hyprpaper is used to set the wallpaper on the system
{
  pkgs,
  config,
  ...
}:
let
  # wallpaper = "/home/${config.hostSpec.username}/Pictures/Wallpapers/wallpaper.jpg";
  # wallpaper = "/home/${config.hostSpec.username}/Pictures/Wallpapers/wallpaper.png";
  wallpaper = "/home/${config.hostSpec.username}/Pictures/Wallpapers/invincible.jpg";
in
{
  # The wallpaper is set by stylix
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      splash_offset = 2.0;
      preload = [
        wallpaper
      ];
      wallpaper = [
        ", ${wallpaper}"
      ];
    };
  };

  home.file."Pictures/Wallpapers" = {
    source = ./wallpapers;
    recursive = true;
  };

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "${pkgs.hyprpaper}/bin/hyprpaper"
    ];
  };
}
