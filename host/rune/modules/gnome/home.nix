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

  dconf = {
    enable = true;
    settings = {
      "org/gnome/shell" = {

        favorite-apps = [
          "org.gnome.Nautilus.desktop"
          "org.wezfurlong.wezterm.desktop"
          "zen.desktop"
          "spotify.desktop"
          "vesktop.desktop"
          "org.telegram.desktop.desktop"
          "code.desktop"
          "Marvel Rivals.desktop"
          "steam.desktop"
        ];

        disable-user-extensions = false;
        enabled-extensions = with pkgs.gnomeExtensions; [
          appindicator.extensionUuid
          blur-my-shell.extensionUuid
          clipboard-indicator.extensionUuid
          dash-to-panel.extensionUuid
          native-window-placement.extensionUuid
          screenshot-window-sizer.extensionUuid
          tiling-shell.extensionUuid
          user-themes.extensionUuid
          vitals.extensionUuid
        ];
      };

      ## Fix some annoying keybindings
      "org/gnome/desktop/wm/keybindings" = {
        close = [ "['<Super>Q']" ];
        switch-to-workspace-up = [ "" ];
        switch-to-workspace-down = [ "" ];
        shift-overview-up = [ "" ];
        shift-overview-down = [ "" ];
        toggle-application-view = [ "" ];
        toggle-message-tray = [ "<Super>a" ];
      };

      "org/gnome/desktop/peripherals/mouse" = {
        speed = 0.0;
        natural-scroll = false;
        accel-profile = "flat";
      };

      "org/gnome/desktop/input-sources/xkb-options" = {
        xkb-options = [
          "compose:menu"
          "lv3:ralt_switch"
          "terminate:ctrl_alt_bksp"
        ];
      };

      "org/gnome/shell/extensions/clipboard-indicator" = {
        toggle-menu = [ "<Super>v" ];
        cache-size = 120;
        history-size = 40;
        pinned-on-bottom = true;
      };

      "org/gnome/shell/extensions/blur-my-shell/panel" = {
        static-blur = false;
        sigma = 50;
      };

      "org/gnome/shell/extensions/dash-to-panel" = {
        appicon-margin = 6;
        appicon-padding = 8;
        dot-position = "TOP";
        dot-style-focused = "DASHES";
        dot-style-unfocused = "DASHES";
        multi-monitors = false;
        panel-positions = builtins.toJSON {
          "0" = "TOP";
          "1" = "TOP";
        };
        scroll-icon-action = "CYCLE_WINDOWS";
        scroll-panel-action = "SWITCH_WORKSPACE";
        trans-panel-opacity = "0.40";
        trans-use-custom-opacity = true;
        tray-padding = 8;
      };

      "org/gnome/shell/extensions/user-theme" = {
        name = "Gruvbox-Dark";
      };
    };
  };
}
