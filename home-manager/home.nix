{ pkgs, ... }:

{  
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

    file = {
      # ".config" = {
      #   recursive = true;
      #   source = ../.config;
      # };
    };

    sessionVariables = {
      EDITOR = "micro";
      VISUAL = "micro";
      XDG_CONFIG_HOME = "$HOME/.config";
    };
  };

  # Programs and Services
  programs.fish = import ./fish.nix { inherit pkgs; }; 
  programs.fastfetch = import ./fastfetch.nix { inherit pkgs; }; 

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
