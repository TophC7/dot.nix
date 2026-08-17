# Vicinae launcher configuration with Matugen theming
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.theme;

  vicinaeTemplate = pkgs.writeText "vicinae-theme-template.toml" ''
    [meta]
    version = 1
    name = "Matugen Material"
    description = "Material You theme generated from wallpaper"
    variant = "${cfg.polarity}"
    inherits = "vicinae-${cfg.polarity}"

    [colors.core]
    background = "{{colors.background.default.hex}}"
    foreground = "{{colors.on_background.default.hex}}"
    secondary_background = "{{colors.surface_container_lowest.default.hex}}"
    border = "{{colors.outline_variant.default.hex}}"
    accent = "{{colors.primary.default.hex}}"

    [colors.accents]
    blue = "{{colors.primary.default.hex}}"
    green = "{{colors.tertiary.default.hex}}"
    magenta = "{{colors.secondary.default.hex}}"
    orange = "{{colors.tertiary_container.default.hex}}"
    purple = "{{colors.primary_container.default.hex}}"
    red = "{{colors.error.default.hex}}"
    yellow = "{{colors.secondary_container.default.hex}}"
    cyan = "{{colors.tertiary_fixed.default.hex}}"
  '';
in
{
  programs.vicinae = lib.mkIf cfg.enable {
    enable = lib.mkDefault true;
    systemd.enable = lib.mkDefault true;
  };

  # Override systemd service environment
  systemd.user.services.vicinae.Service.Environment =
    lib.mkIf config.programs.vicinae.systemd.enable
      [
        "QT_SCALE_FACTOR=1.10"
      ];

  # Matugen generation
  theme.matugen.templates.vicinae = lib.mkIf cfg.enable {
    template = vicinaeTemplate;
    path = ".local/share/vicinae/themes/matugen-material.toml";
  };

  xdg.configFile = {
    "vicinae/vicinae.json" = {
      enable = lib.mkForce false;
    };

    "vicinae/settings.json" = {
      enable = lib.mkForce false;
    };
  };
}
