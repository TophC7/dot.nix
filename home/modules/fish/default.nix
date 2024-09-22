{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile ./init.fish;
    plugins = [
      # Enable a plugin (here grc for colorized command output) from nixpkgs
      { name = "grc"; src = pkgs.fishPlugins.grc.src; }
      { name = "tide"; src = pkgs.fishPlugins.tide.src; }
    ];
  };
}
