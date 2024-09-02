{ pkgs, ... }:
# progams.fish =
{
  enable = true;
  interactiveShellInit = ''
    set fish_greeting # Disable greeting
  '';
  plugins = [
    # Enable a plugin (here grc for colorized command output) from nixpkgs
    { name = "grc"; src = pkgs.fishPlugins.grc.src; }
    { name = "tide"; src = pkgs.fishPlugins.tide.src; }
  ];
}
