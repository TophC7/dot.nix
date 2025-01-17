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
      url = "git@github.com:TophC7/dotfiles.git";
      ref = "hosts";
      rev = "4c2f9faf24e2e90fb7b0b4bce7560da39cbb814a";
    };
  };

}
