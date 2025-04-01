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

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
    configPackages = [ pkgs.hyprland ];
    config.common.default = "*";
  };
}
