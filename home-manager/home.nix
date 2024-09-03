{ pkgs, ... }:

{  
  home.username = "toph";
  home.homeDirectory = "/home/toph";
  home.stateVersion = "24.05";

  # Packages
  home.packages = with pkgs; [
    fastfetch
    fish
    fishPlugins.grc
    fishPlugins.tide
    grc
  ];

  home.file = {
    # ".config" = {
    #   recursive = true;
    #   source = ../.config;
    # };
  };

  home.sessionVariables = {
    EDITOR = "micro";
    VISUAL = "micro";
    XDG_CONFIG_HOME = "$HOME/.config";
  };

  # Programs and Services
  programs.fish = import ./fish.nix { inherit pkgs; }; 
  programs.fastfetch = import ./fastfetch.nix { inherit pkgs; }; 

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
