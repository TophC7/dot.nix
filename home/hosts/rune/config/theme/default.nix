{
  pkgs,
  lib,
  config,
  ...
}:
{
  theme = {
    enable = true;
    image = ./wallpapers/waves.jpg;
    polarity = "dark";

    icon = {
      package = pkgs.papirus-icon-theme.override {
        color = "yellow";
      };
      name = "Papirus";
    };

    pointer = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 16;
    };

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

    base16 = {
      generate = true;
    };

    matugen = {
      scheme = "scheme-expressive";
    };
  };

  # Copy the wallpapers directory to Pictures
  home.file."Pictures/Wallpapers" = {
    source = ./wallpapers;
    recursive = true;
  };
}
