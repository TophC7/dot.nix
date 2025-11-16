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
        zen-browser =
          inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta.meta.desktopFileName;
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
          "Marvel Rivals.desktop"
        ];

        enabled-extensions = [
          "AlphabeticalAppGrid@stuarthayhurst"
          "appindicatorsupport@rgcjonas.gmail.com"
          "auto-accent-colour@Wartybix"
          "blur-my-shell@aunetx"
          "color-picker@tuberry"
          "dash-in-panel@fthx"
          "just-perfection-desktop@just-perfection"
          "monitor-brightness-volume@ailin.nemui"
          "pano@elhan.io"
          "paperwm@paperwm.github.com"
          "quicksettings-audio-devices-hider@marcinjahn.com"
          "quicksettings-audio-devices-renamer@marcinjahn.com"
          "undecorate@sun.wxg@gmail.com"
          "user-theme@gnome-shell-extensions.gcampax.github.com"
          "solaar-extension@sidevesh"
          "Vitals@CoreCoding.com"
        ];
      };
  };
}
