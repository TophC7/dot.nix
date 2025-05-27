{
  lib,
  pkgs,
  ...
}:
{
  # imports = lib.flatten [
  #   ## Common Imports ##
  #   (map lib.custom.relativeToRoot [
  #     "home/global/common/development"
  #   ])

  #   ## Proxy Specific ##
  #   ./config
  # ];

  ## Packages with no needed configs ##
  # home.packages = builtins.attrValues {
  #   inherit (pkgs)
  #     ;
  # };
}
