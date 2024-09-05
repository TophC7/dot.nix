{ pkgs, ... }:
{  
  # Module imports
  imports = [
    ./modules/fastfetch
    ./modules/fish
  ];

  home = {
    username = "toph";
    homeDirectory = "/home/toph";
    stateVersion = "24.05";
    # Packages
    packages = with pkgs; [
      fastfetch
      fish
      fishPlugins.grc
      fishPlugins.tide
      grc
    ];

    # file = {
    #   ".config" = {
    #     recursive = true;
    #     source = ../.config;
    #   };
    # };

    sessionVariables = {
      EDITOR = "micro";
      VISUAL = "micro";
      XDG_CONFIG_HOME = "$HOME/.config";
    };
  }; 

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
