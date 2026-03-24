# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{
  lib,
  pkgs,
  inputs,
  ...
}:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/shell" =
      let
        zen-browser = "zen-beta.desktop";
      in
      {
        favorite-apps = [
          "com.mitchellh.ghostty.desktop"
          "org.gnome.Nautilus.desktop"
          zen-browser
          "code.desktop"
          "spotify.desktop"
          "discord.desktop"
          "org.telegram.desktop.desktop"
          "steam.desktop"
          "ryubing.desktop"
          "Overwatch 2.desktop"
          "Marvel Rivals.desktop"
        ];
      };
  };
}
