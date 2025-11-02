# Mako - Notification daemon for Wayland
{ ... }:
{
  services.mako = {
    enable = true;
    defaultTimeout = 5000;
    borderRadius = 8;
    borderSize = 2;
    padding = "12";
    margin = "10";
    width = 350;
    height = 150;
    icons = true;
    maxIconSize = 64;
    layer = "overlay";
    anchor = "top-right";
    # Styling will be handled by stylix
  };
}
