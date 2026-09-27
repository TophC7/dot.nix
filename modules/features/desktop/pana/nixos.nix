{
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.pana.nixosModules.default ];

  programs.pana.enable = lib.mkDefault true;
}
