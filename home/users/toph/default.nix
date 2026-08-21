_: {
  # Copy the wallpapers directory to Pictures
  home.file."Pictures/Wallpapers" = {
    source = ./wallpapers;
    recursive = true;
  };
}
