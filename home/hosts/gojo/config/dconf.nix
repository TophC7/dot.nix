# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "dash-in-panel@fthx"
        "AlphabeticalAppGrid@stuarthayhurst"
        "color-picker@tuberry"
        "monitor-brightness-volume@ailin.nemui"
        "quicksettings-audio-devices-renamer@marcinjahn.com"
        "Vitals@CoreCoding.com"
        "appindicatorsupport@rgcjonas.gmail.com"
        "paperwm@paperwm.github.com"
        "just-perfection-desktop@just-perfection"
        "pano@elhan.io"
        "blur-my-shell@aunetx"
        "quicksettings-audio-devices-hider@marcinjahn.com"
        "undecorate@sun.wxg@gmail.com"
      ];
      favorite-apps = [
        "com.mitchellh.ghostty.desktop"
        "org.gnome.Nautilus.desktop"
        "win11.desktop"
        "zen.desktop"
        "code.desktop"
        "spotify.desktop"
        "discord.desktop"
        "org.telegram.desktop.desktop"
        "steam.desktop"
        "Ryujinx.desktop"
        "Marvel Rivals.desktop"
      ];
      last-selected-power-profile = "performance";
    };
}
