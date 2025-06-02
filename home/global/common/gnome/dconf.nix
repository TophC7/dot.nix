# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/TextEditor" = lib.mkDefault {
      style-scheme = "stylix";
    };

    "org/gnome/desktop/input-sources" = lib.mkDefault {
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

    "org/gnome/desktop/wm/keybindings" = lib.mkDefault {
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

    "org/gnome/desktop/wm/preferences" = lib.mkForce {
      num-workspaces = 3;
    };

    "org/gnome/mutter" = {
      experimental-features = lib.mkDefault [ "scale-monitor-framebuffer" ];
    };

    "org/gnome/settings-daemon/plugins/color" = lib.mkDefault {
      night-light-enabled = true;
      night-light-schedule-automatic = false;
      night-light-schedule-from = 19.0;
      night-light-temperature = mkUint32 3892;
    };

    "org/gnome/settings-daemon/plugins/media-keys" = lib.mkDefault {
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

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = lib.mkDefault {
      binding = "<Super>t";
      command = "ghostty";
      name = "Terminal";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = lib.mkDefault {
      binding = "<Super>f";
      command = "nautilus";
      name = "Files";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = lib.mkDefault {
      binding = "<Super>e";
      command = "code";
      name = "Code";
    };

    "org/gnome/shell" = {
      disable-user-extensions = lib.mkForce false;
      enabled-extensions = lib.mkDefault [
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
      favorite-apps = lib.mkDefault [
        "com.mitchellh.ghostty.desktop"
        "org.gnome.Nautilus.desktop"
        "zen.desktop"
        "code.desktop"
      ];
      last-selected-power-profile = lib.mkDefault "performance";
    };

    "org/gnome/shell/extensions/alphabetical-app-grid" = {
      folder-order-position = lib.mkDefault "start";
    };

    "org/gnome/shell/extensions/appindicator" = lib.mkDefault {
      icon-brightness = 0.0;
      icon-contrast = 0.0;
      icon-opacity = 240;
      icon-saturation = 0.0;
      icon-size = 0;
      legacy-tray-enabled = true;
      tray-pos = "right";
    };

    "org/gnome/shell/extensions/auto-accent-colour" = lib.mkDefault {
      disable-cache = false;
      hide-indicator = true;
      highlight-mode = true;
    };

    "org/gnome/shell/extensions/blur-my-shell" = lib.mkDefault {
      hacks-level = 1;
      settings-version = 2;
    };

    "org/gnome/shell/extensions/blur-my-shell/appfolder" = lib.mkDefault {
      brightness = 1.0;
      sigma = 85;
    };

    "org/gnome/shell/extensions/blur-my-shell/applications" = lib.mkDefault {
      blacklist = [
        "Plank"
        "com.desktop.ding"
        "Conky"
        ".gamescope-wrapped"
        "steam_app_*"
      ];
      blur = true;
      dynamic-opacity = false;
      enable-all = true;
      opacity = 230;
      sigma = 85;
    };

    "org/gnome/shell/extensions/blur-my-shell/coverflow-alt-tab" = lib.mkDefault {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = lib.mkDefault {
      blur = false;
      brightness = 1.0;
      override-background = true;
      pipeline = "pipeline_default_rounded";
      sigma = 85;
      static-blur = false;
      style-dash-to-dock = 0;
      unblur-in-overview = true;
    };

    "org/gnome/shell/extensions/blur-my-shell/dash-to-panel" = lib.mkDefault {
      blur-original-panel = false;
    };

    "org/gnome/shell/extensions/blur-my-shell/hidetopbar" = lib.mkDefault {
      compatibility = false;
    };

    "org/gnome/shell/extensions/blur-my-shell/lockscreen" = lib.mkDefault {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/overview" = lib.mkDefault {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/panel" = lib.mkDefault {
      brightness = 1.0;
      override-background = true;
      pipeline = "pipeline_default";
      sigma = 85;
      static-blur = false;
    };

    "org/gnome/shell/extensions/blur-my-shell/screenshot" = lib.mkDefault {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/color-picker" = lib.mkDefault {
      auto-copy = true;
      color-picker-shortcut = [ "<Control><Super>c" ];
      enable-format = true;
      enable-notify = false;
      enable-shortcut = true;
      enable-sound = false;
      notify-sound = mkUint32 1;
      notify-style = mkUint32 0;
    };

    "org/gnome/shell/extensions/dash-in-panel" = lib.mkDefault {
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

    "org/gnome/shell/extensions/just-perfection" = lib.mkDefault {
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

    "org/gnome/shell/extensions/pano" = lib.mkDefault {
      global-shortcut = [ "<Super>v" ];
      history-length = 500;
      incognito-shortcut = [ "<Shift><Super>v" ];
      is-in-incognito = false;
      window-position = mkUint32 2;
    };

    "org/gnome/shell/extensions/paperwm" = lib.mkDefault {
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

    "org/gnome/shell/extensions/paperwm/keybindings" = lib.mkDefault {
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

    "org/gnome/shell/extensions/user-theme" = lib.mkDefault {
      name = "Stylix";
    };

    "org/gnome/shell/extensions/vitals" = lib.mkDefault {
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

    "org/gnome/shell/keybindings" = lib.mkDefault {
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

    "org/virt-manager/virt-manager/connections" = lib.mkDefault {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
