{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.theme;
in
{
  options.theme = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable theme configuration";
    };

    image = lib.mkOption {
      type = lib.types.path;
      description = "Path to the wallpaper image";
      example = lib.literalExpression "./wallpapers/waves.jpg";
    };

    icon = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.papirus-icon-theme;
        description = "The icon theme package to use";
        example = lib.literalExpression "pkgs.qogir-icon-theme";
      };

      name = lib.mkOption {
        type = lib.types.str;
        default = "Papirus";
        description = "The name of the icon theme";
        example = "Qogir";
      };
    };

    pointer = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.bibata-cursors;
        description = "The cursor theme package to use";
        example = lib.literalExpression "pkgs.capitaine-cursors";
      };

      name = lib.mkOption {
        type = lib.types.str;
        default = "Bibata-Modern-Classic";
        description = "The name of the cursor theme";
        example = "capitaine-cursors";
      };

      size = lib.mkOption {
        type = lib.types.int;
        default = 16;
        description = "The size of the cursor";
      };
    };

    polarity = lib.mkOption {
      type = lib.types.enum [
        "light"
        "dark"
      ];
      default = "dark";
      description = "Whether to use light or dark theme variant";
    };

    base16 = {
      file = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to a pre-made base16 YAML color scheme file";
        example = lib.literalExpression "./colors.yaml";
      };

      pkg = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Name of a base16 scheme from pkgs.base16-schemes package (for stylix only).
          Will be used as: "$\{pkgs.base16-schemes}/share/themes/<name>.yaml"
        '';
        example = "gruvbox-dark-hard";
      };

      scheme = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "scheme-content"
            "scheme-expressive"
            "scheme-fidelity"
            "scheme-fruit-salad"
            "scheme-monochrome"
            "scheme-neutral"
            "scheme-rainbow"
            "scheme-tonal-spot"
            "scheme-vibrant"
          ]
        );
        default = null;
        description = "Material You scheme type (for matugen/dms only)";
        example = "scheme-expressive";
      };

      generator = lib.mkOption {
        type = lib.types.enum [
          "matugen"
          "stylix"
          "dms"
        ];
        default = "stylix";
        description = ''
          Color scheme generator to use:
          - matugen: Material You colors from wallpaper
          - stylix: Built-in stylix color extraction
          - dms: Dynamic Material Scheme (uses matugen then additional processing)
        '';
      };
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.enable -> (cfg.image != null);
        message = "theme.image must be set when theme is enabled";
      }
      {
        assertion =
          cfg.enable
          -> !(cfg.base16.generator == "stylix" && cfg.base16.file != null && cfg.base16.pkg != null);
        message = "For stylix generator, base16.file and base16.pkg are mutually exclusive - set only one";
      }
      {
        assertion = cfg.enable -> !(cfg.base16.generator == "stylix" && cfg.base16.scheme != null);
        message = "For stylix generator, use base16.pkg or base16.file, not base16.scheme (scheme is for matugen/dms only)";
      }
      {
        assertion =
          cfg.enable
          -> !(
            (cfg.base16.generator == "matugen" || cfg.base16.generator == "dms")
            && (cfg.base16.file != null || cfg.base16.pkg != null)
          );
        message = "For matugen/dms generators, base16.file and base16.pkg cannot be set (colors are generated from wallpaper)";
      }
    ];
  };
}
