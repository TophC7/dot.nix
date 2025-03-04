{ pkgs, ... }:
{
  home.packages = with pkgs; [
    fishPlugins.grc
    fishPlugins.tide
    grc
  ];

  programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile ./init.fish;
    plugins = [
      # Enable a plugin (here grc for colorized command output) from nixpkgs
      {
        name = "grc";
        src = pkgs.fishPlugins.grc.src;
      }
      {
        name = "tide";
        src = pkgs.fishPlugins.tide.src;
      }
    ];
    shellInit = ''
      source "${pkgs.asdf-vm}/share/asdf-vm/asdf.fish"
    '';
  };
}
