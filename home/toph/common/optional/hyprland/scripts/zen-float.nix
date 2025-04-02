{
  pkgs,
  ...
}:
pkgs.writeScript "zen-script" ''
  #!/usr/bin/env fish

  if test (count $argv) -lt 1
      echo "Usage: $argv[0] path/to/your.json"
      exit 1
  end

  set json_file $argv[1]

  function handle
    set -l line $argv[1]
    set -l file_path $argv[2]
    switch $line
        case "windowtitlev2*"
          # Expected format: windowtitlev2>><id>,<title>
          set -l payload (string replace -r '^windowtitlev2>>' "" $line)
          set -l parts (string split "," $payload)
          set -l window_id (string trim $parts[1])
          set -l title (string join "," $parts[2..-1])

          # Debug output
          echo "Extracted window_id: [$window_id]"
          echo "Extracted title: [$title]"

          # Loop over the extensions defined in the JSON file.
          for ext in ( ${pkgs.jq}/bin/jq -r 'keys[]' $file_path )
            echo "Processing extension: [$ext]"
            # Get regex, x and y for the current extension.
            set -l reg ( ${pkgs.jq}/bin/jq -r --arg k $ext '.[$k].regex' $file_path )
            set -l ext_x ( ${pkgs.jq}/bin/jq -r --arg k $ext '.[$k].x' $file_path )
            set -l ext_y ( ${pkgs.jq}/bin/jq -r --arg k $ext '.[$k].y' $file_path )

            # Remove any extra surrounding single quotes.
            set -l reg (string trim -c "'" $reg)

            # Debug: show the extension and regex being used.
            echo "Checking extension [$ext] with regex [$reg] against title [$title]"

            # If the title matches the regex, dispatch floating commands.
            if string match -q -- "*$reg*" "$title"
              echo "$ext window id: $window_id -- setting float mode with size $ext_x x $ext_y"
              hyprctl --batch "dispatch togglefloating address:0x$window_id; dispatch resizewindowpixel exact $ext_x $ext_y,address:0x$window_id;"
              return
            end
          end

        case "*"
          # Do nothing for other events.
    end
  end

  ${pkgs.socat}/bin/socat -U - UNIX-CONNECT:/run/user/1000/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -l line
    handle "$line" "$json_file"
  end
''
