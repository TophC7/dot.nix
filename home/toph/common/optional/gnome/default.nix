{
  pkgs,
  config,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    gruvbox-gtk-theme
    papirus-icon-theme
    numix-cursor-theme
  ];

  gtk = {
    enable = true;

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    theme = {
      name = "Gruvbox-Dark";
      package = pkgs.gruvbox-gtk-theme;
    };

    cursorTheme = {
      name = "Numix-Cursor";
      package = pkgs.numix-cursor-theme;
    };

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };

  # Created with 'dconf dump / | dconf2nix > dconf.nix'
  dconf = {
    enable = true;
    settings = with lib.hm.gvariant; {

      "org/gnome/desktop/background" = {
        color-shading-type = "solid";
        picture-options = "zoom";
        picture-uri = "file:///" + ./wallpaper.jpg;
        picture-uri-dark = "file:///" + ./wallpaper.jpg;
        primary-color = "#000000";
        secondary-color = "#000000";
      };

      "org/gnome/desktop/screensaver" = {
        color-shading-type = "solid";
        picture-options = "zoom";
        picture-uri = "file:///" + ./wallpaper.jpg;
        primary-color = "#241f31";
        secondary-color = "#000000";
      };

      "org/gnome/desktop/interface" = {
        accent-color = "blue";
        color-scheme = "prefer-dark";
        cursor-theme = "Numix-Cursor";
        gtk-theme = "Gruvbox-Dark";
        icon-theme = "Papirus-Dark";
      };

      "org/gnome/desktop/datetime" = {
        automatic-timezone = true;
      };

      "org/gnome/desktop/input-sources" = {
        sources = [
          (mkTuple [
            "xkb"
            "us"
          ])
        ];
        xkb-options = [
          "compose:menu"
          "lv3:ralt_switch"
          "terminate:ctrl_alt_bksp"
        ];
      };

      "org/gnome/desktop/input-sources/xkb-options" = {
        xkb-options = [
          "compose:menu"
          "lv3:ralt_switch"
          "terminate:ctrl_alt_bksp"
        ];
      };

      "org/gnome/desktop/peripherals/mouse" = {
        accel-profile = "flat";
        natural-scroll = false;
        speed = 0.0;
      };

      "org/gnome/desktop/search-providers" = {
        disabled = [
          "org.gnome.seahorse.Application.desktop"
          "org.gnome.Epiphany.desktop"
          "org.gnome.Contacts.desktop"
          "org.gnome.Calendar.desktop"
          "org.gnome.Characters.desktop"
          "org.gnome.clocks.desktop"
          "org.gnome.Calculator.desktop"
        ];
        enabled = [ "org.gnome.Weather.desktop" ];
        sort-order = [
          "org.gnome.Settings.desktop"
          "org.gnome.Contacts.desktop"
          "org.gnome.Nautilus.desktop"
        ];
      };

      "org/gnome/desktop/session" = {
        idle-delay = mkUint32 480;
      };

      "org/gnome/desktop/wm/keybindings" = {
        close = [ "<Super>q" ];
        maximize = [ "" ];
        move-to-monitor-left = [ "" ];
        move-to-monitor-right = [ "" ];
        move-to-workspace-right = [ "" ];
        shift-overview-down = [ "" ];
        shift-overview-up = [ "" ];
        switch-to-workspace-down = [ "" ];
        switch-to-workspace-right = [ ];
        switch-to-workspace-up = [ "" ];
        toggle-application-view = [ "" ];
        toggle-message-tray = [ "<Super>a" ];
        unmaximize = [ "" ];
      };

      "org/gnome/mutter" = {
        dynamic-workspaces = true;
        edge-tiling = false;
      };

      "org/gnome/mutter/keybindings" = {
        toggle-tiled-left = [ "" ];
        toggle-tiled-right = [ "" ];
      };

      "org/gnome/settings-daemon/plugins/color" = {
        night-light-enabled = true;
        night-light-schedule-automatic = true;
        night-light-schedule-from = 18.0;
        night-light-schedule-to = 7.0;
        night-light-temperature = mkUint32 3700;
      };

      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Super>t";
        command = "wezterm";
        name = "Terminal";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        binding = "<Super>f";
        command = "nautilus";
        name = "Files";
      };

      # "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      #   binding = "<Super>f";
      #   command = "rofi?";
      #   name = "rofi";
      # };

      "org/gnome/settings-daemon/plugins/power" = {
        power-button-action = "hibernate";
        sleep-inactive-ac-timeout = 1200;
        sleep-inactive-ac-type = "suspend";
      };

      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [
          "appindicatorsupport@rgcjonas.gmail.com"
          "blur-my-shell@aunetx"
          "clipboard-indicator@tudmotu.com"
          "color-picker@tuberry"
          "dash-to-panel@jderose9.github.com"
          "monitor-brightness-volume@ailin.nemui"
          "native-window-placement@gnome-shell-extensions.gcampax.github.com"
          "screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com"
          "tilingshell@ferrarodomenico.com"
          "user-theme@gnome-shell-extensions.gcampax.github.com"
          "Vitals@CoreCoding.com"
          # pkgs.gnomeExtensions.just-perfection.extensionUuid
          pkgs.gnomeExtensions.alphabetical-app-grid.extensionUuid
          pkgs.gnomeExtensions.quick-settings-audio-devices-hider.extensionUuid
          pkgs.gnomeExtensions.quick-settings-audio-devices-renamer.extensionUuid
        ];
        favorite-apps = [
          "org.gnome.Nautilus.desktop"
          "org.wezfurlong.wezterm.desktop"
          "win11.desktop"
          "zen.desktop"
          "spotify.desktop"
          "vesktop.desktop"
          "org.telegram.desktop.desktop"
          "code.desktop"
          "fleet-jet.desktop"
          "steam.desktop"
          "Marvel Rivals.desktop"
          "org.prismlauncher.PrismLauncher.desktop"
        ];
        last-selected-power-profile = "performance";
      };

      "org/gnome/shell/extensions/blur-my-shell" = {
        settings-version = 2;
      };

      "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
        brightness = 0.6;
        sigma = 30;
      };

      "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
        blur = true;
        brightness = 0.6;
        sigma = 30;
        static-blur = true;
        style-dash-to-dock = 0;
      };

      "org/gnome/shell/extensions/blur-my-shell/panel" = {
        brightness = 0.6;
        sigma = 50;
        static-blur = false;
      };

      "org/gnome/shell/extensions/blur-my-shell/window-list" = {
        brightness = 0.6;
        sigma = 30;
      };

      "org/gnome/shell/extensions/clipboard-indicator" = {
        cache-only-favorites = false;
        cache-size = 120;
        display-mode = 0;
        enable-keybindings = true;
        history-size = 40;
        notify-on-copy = false;
        pinned-on-bottom = true;
        strip-text = false;
        toggle-menu = [ "<Super>v" ];
        topbar-preview-size = 10;
      };

      "org/gnome/shell/extensions/color-picker" = {
        color-history = [
          (mkUint32 3158064)
          1447446
          14538709
          14637907
          1447446
          3355443
          16777215
          1644825
        ];
        color-picker-shortcut = [ "<Super>c" ];
        enable-notify = true;
        enable-shortcut = true;
        enable-systray = true;
        menu-size = mkUint32 8;
        notify-style = mkUint32 0;
        persistent-mode = false;
        preview-style = mkUint32 0;
      };

      "org/gnome/shell/extensions/dash-to-panel" = {
        appicon-margin = 6;
        appicon-padding = 8;
        available-monitors = [
          0
          1
        ];
        dot-position = "TOP";
        dot-style-focused = "DASHES";
        dot-style-unfocused = "DASHES";
        multi-monitors = false;
        panel-positions = ''
          {"0":"TOP","1":"TOP"}
        '';
        primary-monitor = 0;
        scroll-icon-action = "CYCLE_WINDOWS";
        scroll-panel-action = "SWITCH_WORKSPACE";
        trans-panel-opacity = "0.40";
        trans-use-custom-opacity = true;
        tray-padding = 8;
      };

      "org/gnome/shell/extensions/tilingshell" = {
        enable-autotiling = false;
        enable-smart-window-border-radius = false;
        enable-window-border = true;
        inner-gaps = mkUint32 8;
        last-version-name-installed = "16.2";
        layouts-json = "[{\"id\":\"Layout 1\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":0.22,\"height\":0.5,\"groups\":[2,1]},{\"x\":0,\"y\":0.5,\"width\":0.22,\"height\":0.5,\"groups\":[1,2]},{\"x\":0.22,\"y\":0,\"width\":0.2794791666666666,\"height\":0.5,\"groups\":[7,5,2]},{\"x\":0.753125,\"y\":0,\"width\":0.24687499999999998,\"height\":0.5,\"groups\":[4,3]},{\"x\":0.753125,\"y\":0.5,\"width\":0.24687499999999998,\"height\":0.5,\"groups\":[4,3]},{\"x\":0.22,\"y\":0.5,\"width\":0.2797395833333334,\"height\":0.5,\"groups\":[5,6,2]},{\"x\":0.49973958333333335,\"y\":0.5,\"width\":0.2533854166666667,\"height\":0.5,\"groups\":[5,3,6]},{\"x\":0.49947916666666664,\"y\":0,\"width\":0.25364583333333346,\"height\":0.5,\"groups\":[3,5,7]}]},{\"id\":\"Layout 2\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":0.22,\"height\":1,\"groups\":[1]},{\"x\":0.22,\"y\":0,\"width\":0.56,\"height\":1,\"groups\":[1,2]},{\"x\":0.78,\"y\":0,\"width\":0.22,\"height\":1,\"groups\":[2]}]},{\"id\":\"985825\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":1,\"height\":0.5,\"groups\":[1]},{\"x\":0,\"y\":0.5,\"width\":1,\"height\":0.5,\"groups\":[1]}]}]";
        move-window-center = [ "<Super>Return" ];
        outer-gaps = mkUint32 4;
        overridden-settings = "{\"org.gnome.mutter.keybindings\":{\"toggle-tiled-right\":\"['<Super>Right']\",\"toggle-tiled-left\":\"['<Super>Left']\"},\"org.gnome.desktop.wm.keybindings\":{\"maximize\":\"['<Super>Up']\",\"unmaximize\":\"['<Super>Down', '<Alt>F5']\"},\"org.gnome.mutter\":{\"edge-tiling\":\"false\"}}";
        restore-window-original-size = false;
        selected-layouts = [
          [
            "Layout 1"
            "985825"
          ]
          [
            "Layout 1"
            "985825"
          ]
        ];
        span-multiple-tiles-activation-key = [ "1" ];
        span-window-all-tiles = [ "<Control><Super>Page_Up" ];
        span-window-down = [ "<Alt><Super>Down" ];
        span-window-left = [ "<Alt><Super>Left" ];
        span-window-right = [ "<Alt><Super>Right" ];
        span-window-up = [ "<Alt><Super>Up" ];
        tiling-system-activation-key = [ "2" ];
        untile-window = [ "<Control><Super>Page_Down" ];
        window-border-width = mkUint32 1;
      };

      "org/gnome/shell/extensions/user-theme" = {
        name = "Gruvbox-Dark";
      };

      "org/gnome/shell/extensions/vitals" = {
        alphabetize = true;
        hide-icons = false;
        hide-zeros = false;
        hot-sensors = [
          "_memory_usage_"
          "_storage_free_"
          "_network_public_ip_"
          "_processor_usage_"
          "__temperature_avg__"
          "_system_uptime_"
        ];
        icon-style = 0;
        include-static-gpu-info = false;
        menu-centered = false;
        position-in-panel = 4;
        show-gpu = false;
      };

      "org/gtk/gtk4/settings/file-chooser" = {
        show-hidden = true;
      };

      "org/gtk/settings/file-chooser" = {
        date-format = "regular";
        location-mode = "path-bar";
        show-hidden = true;
        show-size-column = true;
        show-type-column = true;
        sidebar-width = 165;
        sort-column = "name";
        sort-directories-first = true;
        sort-order = "ascending";
        type-format = "category";
        window-position = mkTuple [
          102
          102
        ];
        window-size = mkTuple [
          1231
          902
        ];
      };

      "org/virt-manager/virt-manager/connections" = {
        autoconnect = [
          "qemu:///session"
          "qemu:///system"
        ];
        uris = [
          "qemu:///session"
          "qemu:///system"
        ];
      };

      "org/virt-manager/virt-manager/vmlist-fields" = {
        disk-usage = true;
        network-traffic = true;
      };
    };
  };
}
