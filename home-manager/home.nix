{ pkgs, ... }:

{  
  home.username = "toph";
  home.homeDirectory = "/home/toph";
  home.stateVersion = "24.05";

  # Packages
  home.packages = with pkgs; [
    fish
    fishPlugins.grc
    fishPlugins.tide
    grc
  ];

  home.file = {
    ".config/fish" = {
      recursive = true;
      source = ../.config/fish;
    };
  };

  home.sessionVariables = {
    EDITOR = "micro";
    VISUAL = "micro";
    XDG_CONFIG_HOME = "$HOME/.config";
  };

  # Programs and Services
  programs.fish = import ./fish.nix { inherit pkgs; };
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
