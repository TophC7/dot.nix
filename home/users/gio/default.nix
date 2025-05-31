{
  lib,
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
    EDITOR = lib.mkDefault "${lib.getExe pkgs.microsoft-edit}";
    VISUAL = lib.mkDefault "${lib.getExe pkgs.microsoft-edit}";
  };
}
