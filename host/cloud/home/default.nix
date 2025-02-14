{ pkgs, ... }:
{  
  # Module imports
  imports = [
    # Common Modules
      ../../../common/home
  ];

  home.packages = with pkgs; [
      fastfetch
      fish
      fishPlugins.grc
      fishPlugins.tide
      grc
      lazydocker
    ];
}