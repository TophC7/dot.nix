{
  pkgs,
  ...
}:
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
  set value $argv[2]

  if test "$option" = "--up" -o "$option" = "+"
    set op "+"
  else if test "$option" = "--down" -o "$option" = "-"
    set op "-"
  else
    echo "Invalid option. Use --up | + or --down | -"
    exit 1
  end

  # Hardcoded bus numbers from ddcutil detect. Adjust if necessary.
  set buses 10 11

  for bus in $buses
    echo "Changing brightness on bus $bus: ddcutil setvcp 10 $op $value --bus $bus"
    ddcutil setvcp 10 $op $value --bus $bus
  end
''
