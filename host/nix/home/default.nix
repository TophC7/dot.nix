{ pkgs, ... }:
{  
  # Module imports
  imports = [
    # Common Modules
      ../../../common/home
      ../../../common/git
  ];

  home.packages = with pkgs; [
      fastfetch
      fish
      fishPlugins.grc
      fishPlugins.tide
      grc
      nodejs_22
      pnpm
      prettierd
    ];
}