{
  lib,
  pkgs,
  config,
  ...
}:
{
  programs.fastfetch =
    let
      hostname = config.hostSpec.hostName;
      logoFile = ./. + "/host/${hostname}.txt";
      weather = import ./scripts/weather.nix { inherit pkgs; };
      title = import ./scripts/title.nix { inherit pkgs; };
    in
    {
      enable = true;
      settings = {
        logo = {
          # Created with Chafa
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
        # modules = [
        #   {
        #     type = "colors";
        #     symbol = "square";
        #   }
        #   "break"
        #   {
        #     key = "{#31} ┤ user »{#keys}";
        #     type = "title";
        #     format = "{user-name}";
        #   }
        #   {
        #     key = "{#32} ┤ host »{#keys}";
        #     type = "title";
        #     format = "{host-name}";
        #   }
        #   {
        #     key = "{#33} ┤ uptime »{#keys}";
        #     type = "uptime";
        #   }
        #   {
        #     key = "{#34} ┤ distro »{#keys}";
        #     type = "os";
        #   }
        #   {
        #     key = "{#36} ┤ desktop »{#keys}";
        #     type = "de";
        #   }
        #   {
        #     key = "{#32} ┤ shell »{#keys}";
        #     type = "shell";
        #   }
        #   {
        #     key = "{#33} ┤ cpu »{#keys}";
        #     type = "cpu";
        #     showPeCoreCount = true;
        #   }
        #   {
        #     key = "{#34} ┤ disk »{#keys}";
        #     type = "disk";
        #     folders = "/";
        #   }
        #   {
        #     key = "{#35} ┤ memory »{#keys}";
        #     type = "memory";
        #   }
        #   {
        #     key = "{#36} ┤ network »{#keys}";
        #     type = "localip";
        #     format = "{ipv4} ({ifname})";
        #   }
        #   "break"
        #   {
        #     type = "colors";
        #     symbol = "square";
        #   }
        # ];
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
            shell = "${pkgs.fish}/bin/fish";
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
            shell = "${pkgs.fish}/bin/fish";
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
