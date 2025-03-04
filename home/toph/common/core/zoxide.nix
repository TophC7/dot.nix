{
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    options = [
      "--cmd cd" # replace cd with z and zi (via cdi)
    ];
  };
}
