{
  lib,
  pkgs,
  config,
  hostSpec,
  ...
}:
{
  programs.fastfetch =
    let
      hostname = hostSpec.hostName;
      logoFile =
        let
          hostLogoPath = ./. + "/host/images/${hostname}.png";
        in
        if builtins.pathExists hostLogoPath then hostLogoPath else ./host/images/nix.png;
      weather = import ./scripts/weather.nix { inherit pkgs lib; };
      title = import ./scripts/title.nix { inherit pkgs; };
    in
    {
      enable = true;
      settings = {
        logo = {
          type = "kitty";
          source = logoFile;
          width = 21; # columns
          height = 12; # rows
          padding = {
            top = 1;
            right = 2;
            left = 2;
          };
        };
        display = {
          bar = {
            borderLeft = "⦉";
            borderRight = "⦊";
            charElapsed = "⏹";
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
            format = "{artist} - {title} ({#3;32}{6}{#})";
            key = "media   » {#keys}";
            keyColor = "5;92";
            type = "media";
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
