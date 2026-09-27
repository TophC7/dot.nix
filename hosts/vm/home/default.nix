{
  lib,
  pkgs,
  ...
}:
{
  ## VM Specific Imports ##
  imports = lib.fs.scanPaths ./.;

  ## Packages with no needed configs ##
  home.packages = builtins.attrValues {
    inherit (pkgs)
      ## Tools ##
      inspector
      ;
  };
}
