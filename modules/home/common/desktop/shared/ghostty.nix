# Ghostty terminal emulator configuration
# Replaces the default terminal emulator; gnome-terminal/gnome-console is disabled
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  monocraft = inputs.mix-nix.packages.${pkgs.stdenv.hostPlatform.system}.monocraft-nerd-fonts;
in
{
  # Pin the font package so fontconfig can resolve "Monocraft Nerd Font"
  home.packages = [ monocraft ];

  programs.ghostty = {
    enable = lib.mkDefault true;
    enableFishIntegration = lib.mkDefault true;
    settings = {
      theme = lib.mkDefault "dank16";
      # Pin a real monospace + nerd font. Generic "monospace" caused
      # intermittent line-height bumps when Ghostty fell back to fonts
      # with different ascender/descender metrics for special glyphs.
      font-family = lib.mkDefault "Monocraft Nerd Font";
      font-size = lib.mkDefault "11";
      background-opacity = lib.mkDefault "0.85";
      keybind = lib.mkDefault ''shift+enter=text:\x1b\r'';
      window-height = lib.mkDefault 45;
      window-width = lib.mkDefault 145;
      window-inherit-working-directory = lib.mkDefault true;
      adjust-cell-height = 1;
    };
  };

  home.sessionVariables = {
    TERM = lib.mkDefault "ghostty";
  };
}
