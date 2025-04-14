#
# greeter -> tuigreet https://github.com/apognu/tuigreet?tab=readme-ov-file
# display manager -> greetd https://man.sr.ht/~kennylevinsen/greetd/
#

{
  config,
  pkgs,
  lib,
  ...
}:

let
  hostSpec = config.hostSpec.username;
  default = {
    command = "${pkgs.greetd.tuigreet}/bin/tuigreet --asterisks --time --time-format '%I:%M %p | %a • %h | %F' --cmd uwsm start hyprland.desktop";
    user = "toph";
  };
  initial = {
    # command = "${pkgs.hyprland}/bin/Hyprland";
    command = "uwsm start hyprland.desktop";
    user = "toph";
  };
in
{
  #    environment.systemPackages = [ pkgs.greetd.tuigreet ];
  services.greetd = {
    enable = true;

    restart = true;
    settings = rec {
      default_session = default;
      initial_session = initial;
    };
  };
}
