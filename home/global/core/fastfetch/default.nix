{
  lib,
  pkgs,
  config,
  hostSpec,
  ...
}:
{
  #TODO: Scripts might need a rework
  programs.fastfetch =
    let
      hostname = hostSpec.hostName;
      logoFile =
        let
          hostLogoPath = ./. + "/host/${hostname}.txt";
        in
        if builtins.pathExists hostLogoPath then hostLogoPath else ./host/nix.txt;
      weather = import ./scripts/weather.nix { inherit pkgs; };
      title = import ./scripts/title.nix { inherit pkgs; };
    in
    {
      enable = true;
      settings = {
        logo = {
          source = builtins.readFile logoFile;
          type = "data";
          position = "left";
          padding = {
            top = 0;
            right = 0;
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
            text = "printf '%s%s' (string upper (string sub -l 1 $SHELL)) (string lower (string sub -s 2 $SHELL))";
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
