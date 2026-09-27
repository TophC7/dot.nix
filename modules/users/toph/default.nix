{ host, lib, ... }:
{
  mix.fastfetch.logo.source = ./logo.png;

  # Copy the wallpapers directory to Pictures
  home.file."Pictures/Wallpapers" = lib.mkIf (!host.isMinimal) {
    source = ./wallpapers;
    recursive = true;
  };
}
