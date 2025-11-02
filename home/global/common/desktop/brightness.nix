# DDC/CI Brightness Control for External Monitors
{ pkgs, lib, ... }:
let
  # Script to detect and save bus numbers
  detectBusesScript = pkgs.writeScript "detect-buses" ''
    #!${lib.getExe pkgs.fish}

    # Create cache directory if it doesn't exist
    mkdir -p /tmp/ddcutil-cache

    # Detect buses and save to cache file
    set buses (${pkgs.ddcutil}/bin/ddcutil detect 2>/dev/null | ${pkgs.gnugrep}/bin/grep "I2C bus:" | ${pkgs.gnused}/bin/sed 's/.*i2c-\([0-9]\+\).*/\1/' | ${pkgs.coreutils}/bin/sort -n | ${pkgs.coreutils}/bin/tr '\n' ' ' | ${pkgs.gnused}/bin/sed 's/ $//')

    if test -n "$buses"
      echo "$buses" > /tmp/ddcutil-cache/buses
      echo "Detected I2C buses: $buses"
    else
      echo "No I2C buses detected"
      # Create empty file to indicate detection was attempted
      touch /tmp/ddcutil-cache/buses
    end
  '';

  # The brightness control script
  brightnessScript = pkgs.writeScriptBin "brightness" ''
    #!${lib.getExe pkgs.fish}

    # Usage:
    #   brightness --up 10
    #   brightness + 10
    #   brightness --down 15
    #   brightness - 15

    if test (count $argv) -ne 2
      echo "Usage: $argv[0] [--up|+|--down|-] <INTEGER>"
      exit 1
    end

    set option $argv[1]
    set value  $argv[2]

    if test "$option" = "--up" -o "$option" = "+"
      set op "+"
    else if test "$option" = "--down" -o "$option" = "-"
      set op "-"
    else
      echo "Invalid option. Use --up | + or --down | -"
      exit 1
    end

    # Read cached bus numbers
    if test -f /tmp/ddcutil-cache/buses
      set buses_string (cat /tmp/ddcutil-cache/buses)
      # Split the space-separated string into individual bus numbers
      set buses (string split " " "$buses_string")
    else
      echo "Bus cache not found. Make sure ddcutil-detect service is running."
      echo "Try: systemctl --user start ddcutil-detect"
      exit 1
    end

    if test -z "$buses_string"
      echo "No I2C buses found in cache. Check ddcutil configuration."
      exit 1
    end

    echo "Using cached buses: $buses"

    for bus in $buses
      echo "Changing brightness on bus $bus"
      ${pkgs.ddcutil}/bin/ddcutil setvcp 10 $op $value --bus $bus
    end
  '';
in
{
  home.packages = [ brightnessScript ];

  # Systemd user service to detect buses at startup
  systemd.user.services.ddcutil-detect = {
    Unit = {
      Description = "Detect DDC/CI I2C buses for brightness control";
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${detectBusesScript}";
      RemainAfterExit = true;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Timer to periodically refresh the bus cache
  systemd.user.timers.ddcutil-detect = {
    Unit = {
      Description = "Refresh DDC/CI bus detection";
    };

    Timer = {
      OnBootSec = "2min";
      OnUnitActiveSec = "1h";
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
