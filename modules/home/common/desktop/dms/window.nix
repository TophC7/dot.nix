_: {
  programs.niri.settings = {
    layer-rules = [
      {
        matches = [ { namespace = "^vicinae$"; } ];
        shadow = {
          enable = true;
          draw-behind-window = true;
        };
      }
    ];

    window-rules = [
      {
        matches = [
          {
            title = "^Vicinae.*";
            app-id = "";
          }
        ];
        border = {
          enable = true;
          width = 1;
        };
        focus-ring.enable = false;
        clip-to-geometry = true;
      }
      {
        matches = [
          {
            title = "^Settings$";
            app-id = "^org.quickshell$";
          }
          {
            title = "^System Monitor$";
            app-id = "^org.quickshell$";
          }
          {
            title = "^Add Widget$";
            app-id = "^org.quickshell$";
          }
        ];
        open-floating = true;
        default-column-width.proportion = 0.40;
        default-window-height.proportion = 0.60;
      }
    ];
  };
}
