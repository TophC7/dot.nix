{
  flakeRoot,
  lib,
  pkgs,
  ...
}:
{
  imports = map (lib.fs.relativeTo flakeRoot) [
    "modules/home/common/agents"
  ];

  ## Packages with no needed configs ##
  home.packages = with pkgs; [
    # Web Dev
    gh
  ];
}
