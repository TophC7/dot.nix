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
  ];

  home.file = {
    git.dotfiles.source = builtins.fetchGit {
      url = "https://github.com/TophC7/dotfiles/tree/hosts";
      rev = "adecf063251176159fe9edbe0f6dbba432630de4";
    };
  };

}
