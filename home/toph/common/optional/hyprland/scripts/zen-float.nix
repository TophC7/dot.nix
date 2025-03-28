{ pkgs, lib, ... }:
let
  zen-extensions = {
    bitwarden = {
      regex = "'*(Bitwarden Password Manager) - Bitwarden*'";
      x = 500;
      y = 900;
    };
    authenticator = {
      regex = "'*(Authenticator) - Authenticator*'";
      x = 335;
      y = 525;
    };
  };

  zen-json = pkgs.writeText "zen-extensions.json" (builtins.toJSON zen-extensions);
  zen-script = pkgs.writeScript "zen-script" ''
    #!/usr/bin/env fish

      function handle
          set -l line $argv[1]
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
                  for ext in ( ${pkgs.jq}/bin/jq -r 'keys[]' ${zen-json} )
                      echo "Processing extension: [$ext]"
                      # Get regex, x and y for the current extension.
                      set -l reg ( ${pkgs.jq}/bin/jq -r --arg k $ext '.[$k].regex' ${zen-json} )
                      set -l ext_x ( ${pkgs.jq}/bin/jq -r --arg k $ext '.[$k].x' ${zen-json} )
                      set -l ext_y ( ${pkgs.jq}/bin/jq -r --arg k $ext '.[$k].y' ${zen-json} )
                      
                      # Remove any extra surrounding single quotes.
                      set -l reg (string trim -c "'" $reg)
                      
                      # Debug: show the extension and regex being used.
                      echo "Checking extension [$ext] with regex [$reg] against title [$title]"
                      
                      # If the title matches the regex, dispatch floating commands.
                      if string match -q -- "*$reg*" "$title"
                          echo "$ext window id: $window_id -- setting float mode with size $ext_x x $ext_y"
                          hyprctl --batch "dispatch togglefloating address:0x$window_id; dispatch resizewindowpixel exact $ext_x $ext_y,address:0x$window_id; dispatch movewindowpixel exact 64% 3%,address:0x$window_id"
                          return
                      end
                  end
                  ;;
              case "*"
                  # Do nothing for other events.
                  ;;
          end
      end

      ${pkgs.socat}/bin/socat -U - UNIX-CONNECT:/run/user/1000/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -l line
          handle "$line"
      end
  '';
in
{
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "${pkgs.fish}/bin/fish ${zen-script}"
    ];

    windowrulev2 = [
      # Zen Extensions
      "suppressevent maximize, class:^(zen)$"
    ];
  };
}
