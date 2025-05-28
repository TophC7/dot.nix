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
}
