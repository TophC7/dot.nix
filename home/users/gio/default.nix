{
  lib,
  hostSpec,
  ...
}:
{
  imports = [
    (lib.custom.relativeToRoot "home/global/core")
    (lib.optionalAttrs (!hostSpec.isServer) ./theme)
    (lib.custom.relativeToRoot "home/hosts/${hostSpec.hostName}")
  ];

  home.sessionVariables = {
    EDITOR = "${lib.getExe pkgs.microsoft-edit}";
    VISUAL = "${lib.getExe pkgs.microsoft-edit}";
  };
}
