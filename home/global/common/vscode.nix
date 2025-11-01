{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
  };

  # Pkgs used with vscode regularly
  home.packages = builtins.attrValues {
    inherit (pkgs)
      nixfmt-rfc-style # nix formatter
      nixpkgs-review # nix review tool
      biome
      prettier
      ;
  };
}
