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
  user = config.hostSpec.username;
  default = {
    command = "${pkgs.greetd.tuigreet}/bin/tuigreet --asterisks --time --time-format '%I:%M %p | %a • %h | %F' --cmd uwsm start default";
    user = user;
  };
  initial = {
    # command = "${pkgs.hyprland}/bin/Hyprland";
    command = "uwsm start default";
    user = user;
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
