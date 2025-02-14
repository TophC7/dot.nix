{ pkgs, ... }:
{
  programs.fish = {
    shellInit = ''
    source "${pkgs.asdf-vm}/share/asdf-vm/asdf.fish"
    '';
  };
}
