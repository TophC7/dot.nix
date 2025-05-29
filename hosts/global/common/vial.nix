{ pkgs, ... }:
{
  # Allows vial to identify the keyboard
  services.udev.packages = with pkgs; [
    via
  ];
}
