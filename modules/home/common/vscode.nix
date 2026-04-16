{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
  };

  # Pkgs used with vscode regularly
  home.packages = builtins.attrValues {
    inherit (pkgs)
      biome
      nil
      nixfmt
      nixpkgs-review
      prettier
      antigravity-fhs
      ;
  };
}
