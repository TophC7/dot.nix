{ pkgs, inputs, ... }:
{

  home.packages = [
    # pkgs.hyprlandPlugins.hyprexpo
    pkgs.hyprlandPlugins.hyprspace
    pkgs.hyprlandPlugins.hyprscroller
  ];

  wayland.windowManager.hyprland = {
    plugins = [
      # pkgs.hyprlandPlugins.hyprexpo
      pkgs.hyprlandPlugins.hyprspace
      pkgs.hyprlandPlugins.hyprscroller
    ];

    # TODO: Colors and Theme
    settings = {
      windowrulev2 = [
        "bordercolor rgb(191b1c) rgb(ffffff) 25deg, tag: scroller:pinned"
      ];

      plugin = {
        # hyprexpo = {
        #   columns = 3;
        #   gap_size = 5;
        #   bg_col = "rgb(000000)";
        #   workspace_method = "center current"; # [center/first] [workspace] e.g. first 1 or center m+1
        # };
        overview = {
          centerAligned = true;
          hideOverlayLayers = true;
          showSpecialWorkspaces = true;
        };
        scroller = {
          mode = "row";
          center_active_column = true;
          center_active_window = false;
          focus_wrap = true;
          overview_scale_content = false;
          "col.selection_border" = "rgb(191b1c)";
          jump_labels_font = "Monocraft";
          jump_labels_color = "rgb(ffffff)";
          jump_labels_scale = "0.1";
          jump_labels_keys = "qwfpgarstd";
          # monitor_options = ''
          #   (
          #     DP-1 = (
          #       mode = row;
          #       column_default_width = onehalf;
          #       column_widths = onehalf onethird twothirds threefourths;
          #       window_default_height = seveneighths;
          #       window_heights = seveneighths onehalf onethird twothirds
          #     ),
          #     HDMI-A-2 = (
          #       mode = col;
          #       column_default_width = one;
          #       column_widths = one onehalf;
          #       window_default_height = twothirds;
          #       window_heights = seveneighths onehalf onethird twothirds
          #     ),
          #   )'';
          monitor_options = "(DP-1 = (mode = row;column_default_width = onehalf;column_widths = seveneighths threequarters twothirds onehalf onethird;window_default_height = one;window_heights = one seveneighths twothirds onehalf onethird),HDMI-A-2 = (mode = col; column_default_width = one;column_widths = one onehalf;window_default_height = twothirds;window_heights = seveneighths twothirds onehalf onethird),)";
        };
      };
    };
  };
}
