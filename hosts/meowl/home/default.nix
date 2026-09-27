{
  host,
  inputs,
  lib,
  ...
}:
{
  ## Meowl Specific Imports ##
  imports = lib.fs.scanPaths ./.;

  home.packages = [
    inputs.bedrock-on-linux.packages.${host.system}.default
  ];
}
