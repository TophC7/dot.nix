{
  pkgs,
  ...
}:
pkgs.writeScript "steam-map" ''
  #!/usr/bin/env fish
  # Usage: ./steam-map-toggle.fish on|off <monitors.json>

  if test (count $argv) -lt 2
    echo "Usage: $0 on|off <monitors.json>"
    exit 1
  end

  set mode $argv[1]
  set json_file $argv[2]

  if not test -e $json_file
    echo "Error: File $json_file does not exist"
    exit 1
  end

  # Parse the JSON and generate instructions for NON-primary monitors.
  # When 'off', build the monitor string; when 'on', disable the monitor.
  set instructions (${pkgs.jq}/bin/jq -r --arg mode "$mode" '
    .[] |
    if .primary then empty else
      if $mode == "off" then
        .name + "," +
        (.width|tostring) + "x" + (.height|tostring) + "@" + (.refreshRate|tostring) + "," +
        (.x|tostring) + "x" + (.y|tostring) + "," +
        (.scale|tostring) +
        (if has("transform") then ",transform," + (.transform|tostring) else "" end) +
        ",vrr," + (if has("vrr") then (.vrr|tostring) else "0" end)
      else
        .name + ", disable"
      end
    end
  ' $json_file)

  # Execute hyprctl keyword monitor for each instruction.
  for instruction in $instructions
    echo "Running: hyprctl keyword monitor $instruction"
    hyprctl keyword monitor "$instruction"
  end

  # Dispatch the appropriate submap.
  if [ "$mode" = "on" ]  
    hyprctl --batch "dispatch submap steam; dispatch workspace 3"
  else if [ "$mode" = "off" ]
    hyprctl dispatch submap reset
  else
    echo "Invalid mode: $mode"
    exit 1
  end
''
