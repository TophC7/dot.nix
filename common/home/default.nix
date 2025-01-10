{ pkgs, hostName, ... }:
{
  # Module imports
  imports = [
    # Common Modules
    ../fish
    ../fastfetch
  ];

  home = {
    username = "toph";
    homeDirectory = "/home/toph";
    stateVersion = "24.05";
    sessionVariables = {
      HOSTNAME = hostName;
      EDITOR = "micro";
      VISUAL = "micro";
      XDG_CONFIG_HOME = "$HOME/.config";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
