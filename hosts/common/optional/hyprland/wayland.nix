{ pkgs, ... }:
{
  # general packages related to wayland
  environment.systemPackages = with pkgs; [
    grim # screen capture component, required by flameshot
    waypaper # wayland packages(nitrogen analog for wayland)
    swww # backend wallpaper daemon required by waypaper
    wl-clipboard-rs
    wlr-randr
  ];
}
