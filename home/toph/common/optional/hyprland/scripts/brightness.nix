{ pkgs, lib, ... }:

let
  # Define your I2C bus numbers
  # Couldnt find a non hardcoded way to get the bus numbers :(
  busesList = [
    6
    9
  ];
  busesStr = lib.concatStringsSep " " (map toString busesList);
in

pkgs.writeScript "brightness-control" ''
  #!/usr/bin/env fish

  # Usage:
  #   brightness-control --up 10
  #   brightness-control + 10
  #   brightness-control --down 15
  #   brightness-control - 15

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

  # Hard-coded bus list:
  set buses ${busesStr}

  for bus in $buses
    echo "Changing brightness on bus $bus: ddcutil setvcp 10 $op $value --bus $bus"
    ${pkgs.ddcutil}/bin/ddcutil setvcp 10 $op $value --bus $bus
  end
''
