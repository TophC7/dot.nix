{
  config,
  lib,
  pkgs,
  inputs,
  host,
  ...
}:

let
  cfg = config.theme;

  # Determine base16 scheme based on what's configured
  base16Config =
    if cfg.base16.file != null then
      # Use provided file directly
      cfg.base16.file
    else if cfg.base16.package != null then
      # Use package directly
      cfg.base16.package
    else if cfg.base16.generate then
      # Use the generated scheme from theme-spec
      {
        yaml = cfg.base16.generatedScheme;
        use-ifd = "auto";
      }
    else
      # Don't set anything; let stylix auto-generate from wallpaper
      null;
in
{
  imports = [
    inputs.stylix.homeModules.stylix
  ];

  stylix = lib.mkIf cfg.enable (
    {
      enable = true;
      autoEnable = true;
      image = cfg.image;
      polarity = cfg.polarity;

      # Standard font configuration
      fonts = {
        serif = {
          package = pkgs.google-fonts.override { fonts = [ "Laila" ]; };
          name = "Laila";
        };

        sansSerif = {
          package = pkgs.lexend;
          name = "Lexend";
        };

        monospace = {
          package = pkgs.monocraft-nerd-fonts;
          name = "Monocraft";
        };

        emoji = {
          package = pkgs.noto-fonts-color-emoji;
          name = "Noto Color Emoji";
        };

        sizes = {
          applications = 12;
          desktop = 11;
          popups = 11;
          terminal = 12;
        };
      };

      targets = {
        gnome = {
          enable = true;
          useWallpaper = true;
        };
        vscode = {
          enable = false;
        };
      };
    }
    // lib.optionalAttrs (base16Config != null) {
      # Set base16 scheme based on generator and desktop environment
      # Only set if we have a value (null means let stylix auto-generate)
      base16Scheme = base16Config;
    }
  );

  home.pointerCursor = lib.mkIf cfg.enable {
    gtk.enable = true;
    package = cfg.pointer.package;
    name = cfg.pointer.name;
    size = cfg.pointer.size;
  };

  gtk = lib.mkIf cfg.enable {
    enable = true;

    iconTheme = {
      package = cfg.icon.package;
      name = cfg.icon.name;
    };
  };
}
