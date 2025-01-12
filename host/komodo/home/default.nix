{ pkgs, config, ... }:
{
  # Module imports
  imports = [
    # Common Modules
    ../../../common/home
  ];

  home.file = {
    Pool.source = config.lib.file.mkOutOfStoreSymlink "/pool";
    DockerStorage.source = config.lib.file.mkOutOfStoreSymlink "/mnt/DockerStorage";
  };

  home.packages = with pkgs; [
    fastfetch
    fish
    fishPlugins.grc
    fishPlugins.tide
    grc
    lazydocker
  ];
}
