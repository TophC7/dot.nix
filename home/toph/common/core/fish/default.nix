{ pkgs, ... }:
{
  home.packages = with pkgs; [
    fishPlugins.grc
    fishPlugins.tide
    grc
  ];

  home.file.".config/fish/fish_variables" = {
    source = ./fish_variables;
    target = ".config/fish/fish_variables_source";
    onChange = ''cat .config/fish/fish_variables_source > .config/fish/fish_variables && chmod 655 .config/fish/fish_variables'';
  };

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
