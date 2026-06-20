# Common Niri Home Manager configuration for desktop hosts.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  dmsIncludeOrder = [
    "alttab"
    "binds"
    "colors"
    "cursor"
    "layout"
    "outputs"
    "windowrules"
    "wpblur"
  ];

  ensureDmsFile = name: ''
    if [ ! -f "$HOME/.config/niri/dms/${name}.kdl" ]; then
      touch "$HOME/.config/niri/dms/${name}.kdl"
    fi
  '';

  transformToRotation =
    t:
    if t == 0 then
      0
    else if t == 1 then
      90
    else if t == 2 then
      180
    else if t == 3 then
      270
    else
      0;
in
{
  imports = [
    inputs.mix-nix.homeManagerModules.monitors
  ] ++ lib.fs.scanPaths ./.;

  programs.niri.settings = {
    input = {
      keyboard.xkb = {
        layout = lib.mkDefault "us";
        options = lib.mkDefault "terminate:ctrl_alt_bksp,lv3:ralt_switch,compose:menu";
      };

      touchpad = {
        tap = lib.mkDefault true;
        natural-scroll = lib.mkDefault true;
        dwt = lib.mkDefault true;
      };

      mouse.natural-scroll = lib.mkDefault false;
    };

    prefer-no-csd = lib.mkDefault true;

    xwayland-satellite = {
      enable = lib.mkDefault true;
      path = lib.mkDefault (lib.getExe pkgs.xwayland-satellite);
    };

    layout = {
      gaps = lib.mkDefault 8;
      center-focused-column = lib.mkDefault "never";

      preset-column-widths = lib.mkDefault [
        { proportion = 0.25; }
        { proportion = 0.35; }
        { proportion = 0.5; }
        { proportion = 0.65; }
        { proportion = 0.90; }
        { proportion = 1.0; }
      ];

      default-column-width.proportion = lib.mkDefault 0.5;

      border = {
        enable = lib.mkDefault false;
        width = lib.mkDefault 4;
      };

      focus-ring = {
        enable = lib.mkDefault true;
        width = lib.mkDefault 4;
      };

      tab-indicator = {
        enable = lib.mkDefault true;
        position = lib.mkDefault "left";
        width = lib.mkDefault 4;
        gap = lib.mkDefault 8;
        hide-when-single-tab = lib.mkDefault true;
        place-within-column = lib.mkDefault true;
      };
    };

    animations = {
      enable = lib.mkDefault true;
      slowdown = lib.mkDefault 1.0;

      window-open.kind.easing = {
        curve = lib.mkDefault "ease-out-quad";
        duration-ms = lib.mkDefault 150;
      };

      window-close.kind.easing = {
        curve = lib.mkDefault "ease-out-quad";
        duration-ms = lib.mkDefault 150;
      };

      window-movement.kind.spring = {
        damping-ratio = lib.mkDefault 1.0;
        stiffness = lib.mkDefault 800;
        epsilon = lib.mkDefault 0.0001;
      };

      workspace-switch.kind.spring = {
        damping-ratio = lib.mkDefault 1.0;
        stiffness = lib.mkDefault 1000;
        epsilon = lib.mkDefault 0.0001;
      };
    };

    screenshot-path = lib.mkDefault "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

    outputs = lib.mkIf ((config.monitors or [ ]) != [ ]) (
      lib.listToAttrs (
        map (monitor: {
          name = monitor.name;
          value = {
            enable = monitor.enabled;
            mode = {
              width = monitor.width;
              height = monitor.height;
              refresh = monitor.refreshRate + 0.0;
            };
            position = {
              x = monitor.x;
              y = monitor.y;
            };
            scale = monitor.scale;
            transform.rotation = transformToRotation monitor.transform;
            variable-refresh-rate = monitor.vrr or false;
          };
        }) (config.monitors or [ ])
      )
    );
  };

  home.activation.createDmsNiriIncludes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/niri/dms"
    ${lib.concatMapStringsSep "\n" ensureDmsFile dmsIncludeOrder}
  '';
}
