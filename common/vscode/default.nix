{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      # bbenoist.Nix
      # brettm12345.nixfmt-vscode
    ];
  };
}
