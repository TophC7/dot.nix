{
  pkgs,
  lib,
  config,
  ...
}:
{
  theme = {
    enable = true;
    image = ./wallpapers/soraka.png;
    polarity = "dark";

    icon = {
      package = pkgs.papirus-icon-theme.override {
        color = "paleorange";
      };
      name = "Papirus";
    };

    pointer = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 16;
    };

    base16 = {
      scheme = ./soraka.yaml;
      generator = "matugen";
    };
  };

  # Copy the wallpapers directory to Pictures
  home.file."Pictures/Wallpapers" = {
    source = ./wallpapers;
    recursive = true;
  };
}
