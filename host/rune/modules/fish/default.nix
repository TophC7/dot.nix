{ pkgs, ... }:
{
  programs.fish = {
    shellInit = ''
    source "$HOME/.nix-profile/share/asdf-vm/asdf.fish"
    '';
  };
}
