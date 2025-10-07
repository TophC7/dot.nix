{
  lib,
  pkgs,
  config,
  host,
  ...
}:
{
  programs.fastfetch =
    let
      logoFile =
        let
          hostLogoPath = ./. + "/host/${host.network.hostName}.png";
        in
        if builtins.pathExists hostLogoPath then hostLogoPath else ./host/nix.png;
      weather = import ./scripts/weather.nix { inherit pkgs lib; };
      title = import ./scripts/title.nix { inherit pkgs; };
    in
    {
      enable = true;
      settings = {
        logo = {
          type = "kitty";
          source = logoFile;
          width = 26; # columns
          height = 15; # rows
          padding = {
            top = 1;
            right = 2;
            left = 2;
          };
        };
        display = {
          bar = {
            border.left = "⦉";
            border.right = "⦊";
            char.elapsed = "⏹";
            charTotal = "⬝";
            width = 10;
          };
          percent = {
            type = 2;
          };
          separator = "";
        };
        modules = [
          "break"
          {
            key = " ";
            shell = "fish";
            text = "fish ${title}";
            type = "command";
          }
          "break"
          {
            key = "weather » {#keys}";
            keyColor = "1;97";
            shell = "${lib.getExe pkgs.fish}";
            text = "fish ${weather} 'Richmond'";
            type = "command";
          }
          {
            key = "cpu     » {#keys}";
            keyColor = "1;31";
            showPeCoreCount = true;
            type = "cpu";
          }
          {
            format = "{0} {2}";
            key = "gpu     » {#keys}";
            keyColor = "1;93";
            type = "gpu";
            hideType = "integrated";
          }
          {
            format = "{0} ({#3;32}{3}{#})";
            key = "wm      » {#keys}";
            keyColor = "1;32";
            type = "wm";
          }
          {
            text =
              let
                name = lib.getName pkgs.fish;
              in
              "printf '%s%s' (string upper (string sub -l 1 ${name})) (string lower (string sub -s 2 ${name}))";
            key = "shell   » {#keys}";
            keyColor = "1;33";
            type = "command";
            shell = "${lib.getExe pkgs.fish}";
          }
          {
            key = "uptime  » {#keys}";
            keyColor = "1;34";
            type = "uptime";
          }
          {
            folders = "/";
            format = "{0~0,-4} / {2} {13}";
            key = "disk    » {#keys}";
            keyColor = "1;35";
            type = "disk";
          }
          {
            format = "{0~0,-4} / {2} {4}";
            key = "memory  » {#keys}";
            keyColor = "1;36";
            type = "memory";
          }
          {
            format = "{ipv4~0,-3} ({#3;32}{ifname}{#})";
            key = "network » {#keys}";
            keyColor = "1;37";
            type = "localip";
          }
          {
            format = "{2} ({#3;32}{4}{#})";
            key = "kernel  » {#keys}";
            keyColor = "1;94";
            type = "kernel";
          }
          {
            key = "media   » {#keys}";
            keyColor = "5;92";
            type = "command";
            shell = "${lib.getExe pkgs.fish}";
            text = "${lib.getExe pkgs.playerctl} metadata --format '{{ artist }} - {{ title }} ('(set_color green)'{{ playerName }}'(set_color normal)')' 2>/dev/null; or echo 'No media playing'";
          }
          "break"
          {
            symbol = "square";
            type = "colors";
          }
          "break"
        ];
      };
    };
}
