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
    "org/gnome/desktop/app-folders" = {
      folder-children = [
        "System"
        "Utilities"
        "2e37c30a-0da6-400b-b4d1-172dd613cddc"
      ];

    };

    "org/gnome/desktop/app-folders/folders/2e37c30a-0da6-400b-b4d1-172dd613cddc" = {
      apps = [
      ];
      name = "Work";
    };

    "org/gnome/desktop/app-folders/folders/System" = {
      apps = [
        "btop.desktop"
        "org.gnome.DiskUtility.desktop"
        "org.gnome.Extensions.desktop"
        "fish.desktop"
        "io.github.nokse22.inspector.desktop"
        "re.sonny.Junction.desktop"
        "kvantummanager.desktop"
        "io.github.ilya_zlobintsev.LACT.desktop"
        "org.gnome.Logs.desktop"
        "cups.desktop"
        "micro.desktop"
        "nvtop.desktop"
        "protontricks.desktop"
        "qt5ct.desktop"
        "qt6ct.desktop"
        "net.nokyan.Resources.desktop"
        "solaar.desktop"
        "org.gnome.SystemMonitor.desktop"
        "org.gnome.tweaks.desktop"
        "yazi.desktop"
      ];
      name = "X-GNOME-Shell-System.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/Utilities" = {
      apps = [
        "com.dec05eba.gpu_screen_recorder.desktop"
        "org.gnome.Calculator.desktop"
        "org.gnome.Calendar.desktop"
        "org.gnome.Characters.desktop"
        "org.gnome.clocks.desktop"
        "org.gnome.Connections.desktop"
        "org.gnome.Decibels.desktop"
        "org.gnome.Evince.desktop"
        "org.gnome.FileRoller.desktop"
        "org.gnome.font-viewer.desktop"
        "org.gnome.Loupe.desktop"
        "org.gnome.Papers.desktop"
        "org.gnome.seahorse.Application.desktop"
        "org.gnome.Snapshot.desktop"
        "org.gnome.TextEditor.desktop"
        "org.gnome.Totem.desktop"
        "org.gnome.Weather.desktop"
        "org.remmina.Remmina.desktop"
        "page.kramo.Cartridges.desktop"
        "re.sonny.Eloquent.desktop"
        "Vial.desktop"
        "virt-manager.desktop"
      ];
      name = "X-GNOME-Shell-Utilities.directory";
      translate = true;
    };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "icon-view";
      migrated-gtk-settings = true;
      search-filter-time-type = "last_modified";
    };

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
          "steam.desktop"
          "org.telegram.desktop.desktop"
        ];
        enabled-extensions = lib.mkDefault [
          "AlphabeticalAppGrid@stuarthayhurst"
          "appindicatorsupport@rgcjonas.gmail.com"
          "auto-accent-colour@Wartybix"
          "blur-my-shell@aunetx"
          "color-picker@tuberry"
          "dash-in-panel@fthx"
          "flickernaut@imoize.github.io"
          "just-perfection-desktop@just-perfection"
          "monitor-brightness-volume@ailin.nemui"
          "olm-toggle@toph"
          "pano@elhan.io"
          "paperwm@paperwm.github.com"
          "quicksettings-audio-devices-hider@marcinjahn.com"
          "quicksettings-audio-devices-renamer@marcinjahn.com"
          "solaar-extension@sidevesh"
          "undecorate@sun.wxg@gmail.com"
          "user-theme@gnome-shell-extensions.gcampax.github.com"
          "Vitals@CoreCoding.com"
        ];
        last-selected-power-profile = "performance";
        welcome-dialog-last-shown-version = "48.1";
      };

    # "org/gnome/shell/extensions/quicksettings-audio-devices-hider" = {
    #   available-input-names = [
    #     "Digital Input (S/PDIF) \8211 USB  Live camera"
    #     "Microphone \8211 HyperX Cloud Alpha S"
    #     "Microphone \8211 USB  Live camera"
    #   ];
    #   available-output-names = [
    #     "Analog Output \8211 HyperX Cloud Alpha S"
    #     "Digital Output (S/PDIF) \8211 HyperX Cloud Alpha S"
    #     "HDMI / DisplayPort \8211 Rembrandt Radeon High Definition Audio Controller"
    #     "HDMI / DisplayPort 3 \8211 HD-Audio Generic"
    #   ];
    #   excluded-input-names = [
    #     "Digital Input (S/PDIF) – USB  Live camera"
    #     "Digital Input (S/PDIF) \8211 USB  Live camera"
    #     "Digital Input (S/PDIF) 8211 USB  Live camera"
    #     "Digital Input (S/PDIF) 8211 USB  Live camera"
    #     "Microphone – USB  Live camera"
    #     "Microphone \8211 USB  Live camera"
    #     "Microphone 8211 USB  Live camera"
    #     "Microphone 8211 USB  Live camera"
    #   ];
    #   excluded-output-names = [
    #     # "Analog Output – HyperX Cloud Alpha S"
    #     # "Analog Output \8211 HyperX Cloud Alpha S"
    #     # "Analog Output 8211 HyperX Cloud Alpha S"
    #     # "Analog Output 8211 HyperX Cloud Alpha S"
    #     "HDMI / DisplayPort – Rembrandt Radeon High Definition Audio Controller"
    #     "HDMI / DisplayPort \8211 Rembrandt Radeon High Definition Audio Controller"
    #     "HDMI / DisplayPort 8211 Rembrandt Radeon High Definition Audio Controller"
    #     "HDMI / DisplayPort 8211 Rembrandt Radeon High Definition Audio Controller"
    #   ];
    # };

    # "org/gnome/shell/extensions/quicksettings-audio-devices-renamer" = {
    #   input-names-map = [
    #     (lib.hm.gvariant.mkDictionaryEntry [
    #       "Microphone – USB  Live camera"
    #       "NO"
    #     ])
    #     (lib.hm.gvariant.mkDictionaryEntry [
    #       "Digital Input (S/PDIF) – USB  Live camera"
    #       "NO"
    #     ])
    #     (lib.hm.gvariant.mkDictionaryEntry [
    #       "Microphone – HyperX Cloud Alpha S"
    #       "Cloud S"
    #     ])
    #   ];
    #   output-names-map = [
    #     (lib.hm.gvariant.mkDictionaryEntry [
    #       "HDMI / DisplayPort 3 – HD-Audio Generic"
    #       "ROG"
    #     ])
    #     (lib.hm.gvariant.mkDictionaryEntry [
    #       "HDMI / DisplayPort 3 – HDA ATI HDMI"
    #       "ROG"
    #     ])
    #     (lib.hm.gvariant.mkDictionaryEntry [
    #       "HDMI / DisplayPort – Rembrandt Radeon High Definition Audio Controller"
    #       "NO"
    #     ])
    #     (lib.hm.gvariant.mkDictionaryEntry [
    #       "Analog Output – HyperX Cloud Alpha S"
    #       "Cloud S - 7.1"
    #     ])
    #     (lib.hm.gvariant.mkDictionaryEntry [
    #       "Digital Output (S/PDIF) – HyperX Cloud Alpha S"
    #       "Cloud S"
    #     ])
    #   ];
    # };
  };
}
