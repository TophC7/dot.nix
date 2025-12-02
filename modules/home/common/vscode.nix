{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
  };

  # Pkgs used with vscode regularly
  home.packages = builtins.attrValues {
    inherit (pkgs)
      biome
      nixfmt-rfc-style
      nixpkgs-review
      prettier
      ;
  };
}
