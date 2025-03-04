{ pkgs, ... }:
{
  programs.fish = {
    shellInit = ''
      source "${pkgs.asdf-vm}/share/asdf-vm/asdf.fish"
    '';
  };

  home.packages = builtins.attrValues {
    inherit (pkgs)
      asdf-vm
      ;
  };
}
