{
  pkgs,
  inputs,
  lib,
  ...
}:
let
  qogir = pkgs.qogir-icon-theme.override {
    colorVariants = [
      "dark"
      "standard"
    ];
    themeVariants = [
      "ubuntu"
    ];
  };

in
{
  imports = [
    inputs.stylix.homeManagerModules.stylix
  ];

  stylix = {
    enable = true;
    autoEnable = true;
    base16Scheme = ./soraka.yaml;
    image = ./wallpapers/soraka.jpg;
    polarity = "dark";
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
        package = pkgs.noto-fonts-emoji;
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
        enable = true;
        # profileNames = [ "Stylix" ];
      };
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
  };

  gtk = {
    enable = true;

    iconTheme = {
      # package = qogir;
      # name = "Qogir";
      package = (
        pkgs.papirus-icon-theme.override {
          color = "violet";
        }
      );
      name = "Papirus";
    };
  };

  home.file = {
    "Pictures/Wallpapers" = {
      source = ./wallpapers;
      recursive = true;
    };
  };
}
