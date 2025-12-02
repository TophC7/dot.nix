{
  flakeRoot,
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    ## VM Specific Imports ##
    (lib.fs.scanPaths ./.)

    ## Additional Imports ##
    (map (lib.fs.relativeTo flakeRoot) [
      "modules/home/common/vscode.nix"
      "modules/home/common/xdg.nix"
      "modules/home/common/zen.nix"
    ])
  ];

  ## Packages with no needed configs ##
  home.packages = builtins.attrValues {
    inherit (pkgs)
      ## Tools ##
      inspector
      ;
  };
}
