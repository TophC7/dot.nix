{ pkgs, ... }:
let
  patched-openssh = pkgs.openssh.overrideAttrs (prev: {
    patches = (prev.patches or [ ]) ++ [ ./openssh.patch ];
  });
in
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhsWithPackages (_: [ patched-openssh ]);
  };

  # Pkgs used with vscode regularly
  home.packages = builtins.attrValues {
    inherit (pkgs)
      nixfmt-rfc-style # nix formatter
      nixpkgs-review # nix review tool
      biome
      ;
  };
}
