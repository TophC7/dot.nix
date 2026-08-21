{
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.pana.homeModules.default ] ++ lib.fs.scanPaths ./.;

  programs.pana.enable = lib.mkDefault true;
}
