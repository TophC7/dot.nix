# Swaylock & Swayidle - Screen lock and idle management
{ lib, pkgs, ... }:
{
  # Swaylock - screen locker
  programs.swaylock = {
    enable = true;
    settings = {
      show-failed-attempts = true;
      indicator-radius = 100;
      indicator-thickness = 20;
      # Styling will be handled by stylix
    };
  };

  # Swayidle - idle management
  services.swayidle = {
    enable = true;
    events = [
      {
        event = "before-sleep";
        command = "${lib.getExe pkgs.swaylock} -f";
      }
      {
        event = "lock";
        command = "${lib.getExe pkgs.swaylock} -f";
      }
    ];
    timeouts = [
      {
        timeout = 300;
        command = "${lib.getExe pkgs.swaylock} -f";
      }
      {
        timeout = 600;
        command = "niri msg action power-off-monitors";
        resumeCommand = "niri msg action power-on-monitors";
      }
    ];
  };
}
