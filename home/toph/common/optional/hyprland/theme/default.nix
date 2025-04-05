{
  pkgs,
  inputs,
  lib,
  ...
}:
let
  path = lib.custom.relativeToRoot "pkgs/common/monocraft-nerd-fonts/package.nix";
  monocraft-nerd-fonts = pkgs.callPackage path { inherit pkgs; };
in
{
  imports = [
    inputs.stylix.homeManagerModules.stylix
  ];

  stylix = {
    enable = true;
    autoEnable = true;
    base16Scheme = ./invincible.yaml;
    image = ./wallpapers/invincible.jpg;
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
        package = monocraft-nerd-fonts;
        name = "Monocraft";
      };

      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };

    };
    targets = {
      hyprpaper.enable = true;
      vscode = {
        enable = false;
        profileNames = [ "Stylix" ];
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
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
  };

  home.file = {
    # ".config/stylix/invincible.yaml" = {
    #   source = ./invincible.yaml;
    # };

    "Pictures/Wallpapers" = {
      source = ./wallpapers;
      recursive = true;
    };
  };
}
