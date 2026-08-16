{
  flakeRoot,
  host,
  inputs,
  lib,
  ...
}:
{
  imports = lib.flatten [
    ## Meowl Specific Imports ##
    (lib.fs.scanPaths ./.)

    ## Additional Imports ##
    (map (lib.fs.relativeTo flakeRoot) [
      "modules/home/common/gaming"
      "modules/home/common/xdg.nix"
      "modules/home/common/zen.nix"
    ])
  ];

  home.packages = [
    inputs.bedrock-on-linux.packages.${host.system}.default
  ];
}
