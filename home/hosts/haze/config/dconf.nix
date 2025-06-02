# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "com.mitchellh.ghostty.desktop"
        "org.gnome.Nautilus.desktop"
        "zen.desktop"
        "code.desktop"
        "spotify.desktop"
        "discord.desktop"
        "org.telegram.desktop.desktop"
        "steam.desktop"
        "Ryujinx.desktop"
        "Overwatch 2.desktop"
        "Marvel Rivals.desktop"
      ];
    };
  };
}
