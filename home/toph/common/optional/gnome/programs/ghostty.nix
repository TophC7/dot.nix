{
  # Replaces the default terminal emulator; gnome-terminal/gnome-console is disabled
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      theme = "stylix";
      font-family = "monospace";
      font-size = "11";
      background-opacity = "0.85";
    };
  };

  home.sessionVariables = {
    TERM = "ghostty";
  };
}
