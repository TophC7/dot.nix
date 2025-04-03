{ pkgs, ... }:
{
  home.packages = [ pkgs.walker ];

  wayland.windowManager.hyprland.settings.exec-once = [
    ''walker --gapplication-service''
  ];

  home.file."~/.config/walker/config.toml" = {
    source = ./config.toml;
    target = ".config/walker/config.toml";
  };
}
