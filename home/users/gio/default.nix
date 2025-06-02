{
  lib,
  pkgs,
  hostSpec,
  ...
}:
{
  imports = [
    (lib.custom.relativeToRoot "home/global/core")
    ./config
    (lib.custom.relativeToRoot "home/hosts/${hostSpec.hostName}")
  ];

  home.sessionVariables = {
    EDITOR = "${lib.getExe pkgs.microsoft-edit}";
    VISUAL = "${lib.getExe pkgs.microsoft-edit}";
  };
}
