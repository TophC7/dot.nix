# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/TextEditor" = {
      style-scheme = "stylix";
    };

    "org/gnome/desktop/app-folders" = {
      folder-children = [
        "System"
        "Utilities"
        "Useless Launchers"
      ];
    };

    "org/gnome/desktop/app-folders/folders/System" = {
      apps = [
        "org.gnome.baobab.desktop"
        "org.gnome.DiskUtility.desktop"
        "org.gnome.Logs.desktop"
        "org.gnome.SystemMonitor.desktop"
        "org.gnome.tweaks.desktop"
      ];
      name = "X-GNOME-Shell-System.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/Utilities" = {
      apps = [
        "org.gnome.Connections.desktop"
        "org.gnome.FileRoller.desktop"
        "org.gnome.font-viewer.desktop"
        "org.gnome.Loupe.desktop"
        "org.gnome.seahorse.Application.desktop"
      ];
      name = "X-GNOME-Shell-Utilities.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/Useless" = {
      apps = [
        "fish.desktop"
        "ranger.desktop"
      ];
      name = "Useless Launchers";
      translate = false;
    };

    "org/gnome/desktop/input-sources" = {
      sources = [
        (mkTuple [
          "xkb"
          "us"
        ])
      ];
      xkb-options = [
        "terminate:ctrl_alt_bksp"
        "lv3:ralt_switch"
        "compose:menu"
      ];
    };

    "org/gnome/desktop/wm/keybindings" = {
      maximize = [ ];
      move-to-monitor-down = [ ];
      move-to-monitor-left = [ ];
      move-to-monitor-right = [ ];
      move-to-monitor-up = [ ];
      move-to-workspace-down = [ "<Control><Shift><Alt>Down" ];
      move-to-workspace-left = [ ];
      move-to-workspace-right = [ ];
      move-to-workspace-up = [ "<Control><Shift><Alt>Up" ];
      shift-overview-down = [ "" ];
      shift-overview-up = [ "" ];
      switch-applications = [ ];
      switch-applications-backward = [
        "<Shift><Super>Tab"
        "<Shift><Alt>Tab"
      ];
      switch-group = [
        "<Super>Above_Tab"
        "<Alt>Above_Tab"
      ];
      switch-group-backward = [
        "<Shift><Super>Above_Tab"
        "<Shift><Alt>Above_Tab"
      ];
      switch-input-source = [ ];
      switch-input-source-backward = [ ];
      switch-panels = [ "<Control><Alt>Tab" ];
      switch-panels-backward = [ "<Shift><Control><Alt>Tab" ];
      switch-to-workspace-1 = [ ];
      switch-to-workspace-down = [ "" ];
      switch-to-workspace-last = [ ];
      switch-to-workspace-left = [ ];
      switch-to-workspace-right = [ ];
      switch-to-workspace-up = [ "" ];
      toggle-application-view = [ "" ];
      toggle-message-tray = [ "" ];
      unmaximize = [ ];
    };

    "org/gnome/desktop/wm/preferences" = {
      num-workspaces = 3;
    };

    "org/gnome/mutter" = {
      experimental-features = [ "scale-monitor-framebuffer" ];
    };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "icon-view";
      migrated-gtk-settings = true;
      search-filter-time-type = "last_modified";
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = true;
      night-light-schedule-automatic = false;
      night-light-schedule-from = 19.0;
      night-light-temperature = mkUint32 3892;
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
      ];
      next = [ "AudioNext" ];
      play = [ "AudioPlay" ];
      previous = [ "AudioPrev" ];
      reboot = [ "<Super>r" ];
      rotate-video-lock-static = [ ];
      shutdown = [ "<Super>x" ];
      volume-down = [ "AudioLowerVolume" ];
      volume-mute = [ "AudioMute" ];
      volume-up = [ "AudioRaiseVolume" ];
      www = [ "<Super>w" ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>t";
      command = "ghostty";
      name = "Terminal";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      binding = "<Super>f";
      command = "nautilus";
      name = "Files";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      binding = "<Super>e";
      command = "code";
      name = "Code";
    };

    "org/gnome/shell" = {
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
        "appeditor-local-application-1.desktop"
        "Ryujinx.desktop"
        "Marvel Rivals.desktop"
      ];
      last-selected-power-profile = "performance";
      welcome-dialog-last-shown-version = "48.1";
    };

    "org/gnome/shell/extensions/alphabetical-app-grid" = {
      folder-order-position = "start";
    };

    "org/gnome/shell/extensions/appindicator" = {
      icon-brightness = 0.0;
      icon-contrast = 0.0;
      icon-opacity = 240;
      icon-saturation = 0.0;
      icon-size = 0;
      legacy-tray-enabled = true;
      tray-pos = "right";
    };

    "org/gnome/shell/extensions/blur-my-shell" = {
      hacks-level = 1;
      settings-version = 2;
    };

    "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
      brightness = 1.0;
      sigma = 85;
    };

    "org/gnome/shell/extensions/blur-my-shell/applications" = {
      blacklist = [
        "Plank"
        "com.desktop.ding"
        "Conky"
        ".gamescope-wrapped"
        "steam_app_2993780"
      ];
      blur = true;
      dynamic-opacity = false;
      enable-all = true;
      opacity = 230;
      sigma = 85;
    };

    "org/gnome/shell/extensions/blur-my-shell/coverflow-alt-tab" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      blur = false;
      brightness = 1.0;
      override-background = true;
      pipeline = "pipeline_default_rounded";
      sigma = 85;
      static-blur = false;
      style-dash-to-dock = 0;
      unblur-in-overview = true;
    };

    "org/gnome/shell/extensions/blur-my-shell/dash-to-panel" = {
      blur-original-panel = false;
    };

    "org/gnome/shell/extensions/blur-my-shell/hidetopbar" = {
      compatibility = false;
    };

    "org/gnome/shell/extensions/blur-my-shell/lockscreen" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/overview" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      brightness = 1.0;
      override-background = true;
      pipeline = "pipeline_default";
      sigma = 85;
      static-blur = false;
    };

    "org/gnome/shell/extensions/blur-my-shell/screenshot" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/dash-in-panel" = {
      button-margin = 6;
      center-dash = true;
      colored-dot = true;
      icon-size = 32;
      move-date = true;
      panel-height = 46;
      show-apps = false;
      show-dash = false;
      show-label = true;
    };

    "org/gnome/shell/extensions/just-perfection" = {
      accessibility-menu = true;
      activities-button = false;
      clock-menu = true;
      clock-menu-position = 1;
      dash = true;
      dash-app-running = true;
      dash-separator = false;
      keyboard-layout = true;
      max-displayed-search-results = 0;
      panel-in-overview = true;
      quick-settings = true;
      quick-settings-dark-mode = true;
      ripple-box = true;
      show-apps-button = false;
      support-notifier-showed-version = 34;
      support-notifier-type = 0;
      top-panel-position = 0;
      window-preview-close-button = true;
      workspace = false;
      workspace-switcher-size = 0;
      workspaces-in-app-grid = true;
    };

    "org/gnome/shell/extensions/pano" = {
      global-shortcut = [ "<Super>v" ];
      history-length = 500;
      incognito-shortcut = [ "<Shift><Super>v" ];
      is-in-incognito = false;
      window-position = mkUint32 2;
    };

    "org/gnome/shell/extensions/paperwm" = {
      cycle-height-steps = [
        0.25
        0.3
        0.5
        0.7
        0.95
      ];
      cycle-width-steps = [
        0.25
        0.3
        0.5
        0.7
        0.95
      ];
      default-focus-mode = 1;
      disable-topbar-styling = true;
      edge-preview-enable = true;
      edge-preview-timeout-enable = false;
      gesture-enabled = false;
      gesture-horizontal-fingers = 0;
      horizontal-margin = 8;
      last-used-display-server = "Wayland";
      restore-attach-modal-dialogs = "true";
      restore-edge-tiling = "true";
      restore-workspaces-only-on-primary = "true";
      selection-border-size = 4;
      show-focus-mode-icon = false;
      show-open-position-icon = false;
      show-window-position-bar = false;
      show-workspace-indicator = false;
      vertical-margin = 8;
      vertical-margin-bottom = 8;
      window-gap = 8;
      winprops = [
        ''
          {"wm_class":"com.mitchellh.ghostty","scratch_layer":true}
        ''
        ''
          {"wm_class":"code","preferredWidth":"70%"}
        ''
        ''
          {"wm_class":"discord","preferredWidth":"100%","spaceIndex":1}
        ''
        ''
          {"wm_class":"org.gnome.Nautilus","scratch_layer":true}
        ''
        ''
          {"wm_class":"gnome-control-center","scratch_layer":true}
        ''
      ];
    };

    "org/gnome/shell/extensions/paperwm/keybindings" = {
      center = [ "<Super>c" ];
      center-horizontally = [ "" ];
      center-vertically = [ "" ];
      close-window = [ "<Super>q" ];
      cycle-height = [ "<Alt><Super>Up" ];
      cycle-height-backwards = [ "<Alt><Super>Down" ];
      cycle-width = [ "<Alt><Super>Right" ];
      cycle-width-backwards = [ "<Alt><Super>Left" ];
      live-alt-tab = [ "<Alt>Tab" ];
      live-alt-tab-backward = [ "" ];
      live-alt-tab-scratch = [ "" ];
      live-alt-tab-scratch-backward = [ "" ];
      move-down = [ "<Shift><Super>Down" ];
      move-down-workspace = [ "<Control><Super>Down" ];
      move-left = [ "<Shift><Super>Left" ];
      move-monitor-above = [ "" ];
      move-monitor-below = [ "" ];
      move-monitor-left = [ "<Control><Super>Left" ];
      move-monitor-right = [ "<Control><Super>Right" ];
      move-previous-workspace = [ "" ];
      move-previous-workspace-backward = [ "" ];
      move-right = [ "<Shift><Super>Right" ];
      move-space-monitor-above = [ "" ];
      move-space-monitor-below = [ "" ];
      move-space-monitor-left = [ "" ];
      move-space-monitor-right = [ "" ];
      move-up = [ "<Shift><Super>Up" ];
      move-up-workspace = [ "<Control><Super>Up" ];
      new-window = [ "<Super>n" ];
      previous-workspace = [ "" ];
      previous-workspace-backward = [ "" ];
      swap-monitor-above = [ "" ];
      swap-monitor-below = [ "" ];
      swap-monitor-left = [ "" ];
      swap-monitor-right = [ "" ];
      switch-down-workspace = [ "<Super>Page_Down" ];
      switch-focus-mode = [ "<Alt><Super>a" ];
      switch-monitor-above = [ "" ];
      switch-monitor-below = [ "" ];
      switch-monitor-left = [ "" ];
      switch-monitor-right = [ "" ];
      switch-next = [ "" ];
      switch-open-window-position = [ "" ];
      switch-previous = [ "" ];
      switch-up-workspace = [ "<Super>Page_Up" ];
      take-window = [ "" ];
      toggle-maximize-width = [ "" ];
      toggle-scratch = [ "<Super>BackSpace" ];
      toggle-scratch-layer = [ "<Control><Super>BackSpace" ];
      toggle-scratch-window = [ "" ];
      toggle-top-and-position-bar = [ "" ];
    };

    "org/gnome/shell/extensions/paperwm/workspaces" = {
      list = [
        "d3fe7ebc-4b28-4738-98b8-d4cd3e31cf7f"
        "5291a627-8b95-48f4-bfd4-1f9e56b5234b"
        "77949e36-39cc-4831-ad12-48054589a02a"
        "407eab83-d3cd-4974-8d32-8fe0de05579c"
        "0617efdf-c223-434c-9fd2-8bf9bedf9700"
      ];
    };

    "org/gnome/shell/extensions/paperwm/workspaces/0617efdf-c223-434c-9fd2-8bf9bedf9700" = {
      index = 4;
    };

    "org/gnome/shell/extensions/paperwm/workspaces/407eab83-d3cd-4974-8d32-8fe0de05579c" = {
      index = 3;
    };

    "org/gnome/shell/extensions/paperwm/workspaces/5291a627-8b95-48f4-bfd4-1f9e56b5234b" = {
      index = 1;
      show-top-bar = true;
    };

    "org/gnome/shell/extensions/paperwm/workspaces/77949e36-39cc-4831-ad12-48054589a02a" = {
      index = 2;
    };

    "org/gnome/shell/extensions/paperwm/workspaces/d3fe7ebc-4b28-4738-98b8-d4cd3e31cf7f" = {
      index = 0;
      show-top-bar = true;
    };

    "org/gnome/shell/extensions/quicksettings-audio-devices-hider" = {
      available-input-names = [
        "Digital Input (S/PDIF) \8211 USB  Live camera"
        "Microphone \8211 HyperX Cloud Alpha S"
        "Microphone \8211 USB  Live camera"
      ];
      available-output-names = [
        "Analog Output \8211 HyperX Cloud Alpha S"
        "Digital Output (S/PDIF) \8211 HyperX Cloud Alpha S"
        "HDMI / DisplayPort \8211 Rembrandt Radeon High Definition Audio Controller"
        "HDMI / DisplayPort 3 \8211 HD-Audio Generic"
      ];
      excluded-input-names = [
        "Digital Input (S/PDIF) – USB  Live camera"
        "Digital Input (S/PDIF) \8211 USB  Live camera"
        "Digital Input (S/PDIF) 8211 USB  Live camera"
        "Digital Input (S/PDIF) 8211 USB  Live camera"
        "Microphone – USB  Live camera"
        "Microphone \8211 USB  Live camera"
        "Microphone 8211 USB  Live camera"
        "Microphone 8211 USB  Live camera"
      ];
      excluded-output-names = [
        "Analog Output – HyperX Cloud Alpha S"
        "Analog Output \8211 HyperX Cloud Alpha S"
        "Analog Output 8211 HyperX Cloud Alpha S"
        "Analog Output 8211 HyperX Cloud Alpha S"
        "HDMI / DisplayPort – Rembrandt Radeon High Definition Audio Controller"
        "HDMI / DisplayPort \8211 Rembrandt Radeon High Definition Audio Controller"
        "HDMI / DisplayPort 8211 Rembrandt Radeon High Definition Audio Controller"
        "HDMI / DisplayPort 8211 Rembrandt Radeon High Definition Audio Controller"
      ];
    };

    "org/gnome/shell/extensions/quicksettings-audio-devices-renamer" = {
      input-names-map = [
        (lib.hm.gvariant.mkDictionaryEntry [
          "Microphone – USB  Live camera"
          "NO"
        ])
        (lib.hm.gvariant.mkDictionaryEntry [
          "Digital Input (S/PDIF) – USB  Live camera"
          "NO"
        ])
        (lib.hm.gvariant.mkDictionaryEntry [
          "Microphone – HyperX Cloud Alpha S"
          "Cloud S"
        ])
      ];
      output-names-map = [
        (lib.hm.gvariant.mkDictionaryEntry [
          "HDMI / DisplayPort 3 – HD-Audio Generic"
          "ROG"
        ])
        (lib.hm.gvariant.mkDictionaryEntry [
          "HDMI / DisplayPort – Rembrandt Radeon High Definition Audio Controller"
          "NO"
        ])
        (lib.hm.gvariant.mkDictionaryEntry [
          "Analog Output – HyperX Cloud Alpha S"
          "NO"
        ])
        (lib.hm.gvariant.mkDictionaryEntry [
          "Digital Output (S/PDIF) – HyperX Cloud Alpha S"
          "Cloud S"
        ])
      ];
      # input-names-map = ''{'Microphone – USB  Live camera': 'NO', 'Digital Input (S/PDIF) – USB  Live camera': 'NO', 'Microphone – HyperX Cloud Alpha S': 'Cloud S'}'';
      # output-names-map = ''{'HDMI / DisplayPort 3 – HD-Audio Generic': 'ROG', 'HDMI / DisplayPort – Rembrandt Radeon High Definition Audio Controller': 'NO', 'Analog Output – HyperX Cloud Alpha S': 'NO', 'Digital Output (S/PDIF) – HyperX Cloud Alpha S': 'Cloud S'}'';
    };

    "org/gnome/shell/extensions/user-theme" = {
      name = "Stylix";
    };

    "org/gnome/shell/extensions/vitals" = {
      alphabetize = true;
      fixed-widths = true;
      hide-icons = false;
      hide-zeros = true;
      icon-style = 1;
      include-static-gpu-info = true;
      include-static-info = true;
      menu-centered = false;
      position-in-panel = 0;
      show-fan = false;
      show-gpu = true;
      show-memory = true;
      show-network = true;
      show-processor = true;
      show-storage = true;
      show-system = true;
      show-temperature = true;
      show-voltage = false;
      use-higher-precision = false;
    };

    "org/gnome/shell/keybindings" = {
      focus-active-notification = [ ];
      screenshot = [ "Print" ];
      screenshot-window = [ ];
      shift-overview-down = [ ];
      shift-overview-up = [ ];
      show-screen-recording-ui = [ ];
      show-screenshot-ui = [ "<Shift>Print" ];
      toggle-application-view = [ "Home" ];
      toggle-message-tray = [ "<Super>s" ];
      toggle-quick-settings = [ "<Super>a" ];
    };

    "org/gnome/shell/world-clocks" = {
      locations = [ ];
    };

    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
