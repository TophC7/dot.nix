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
}
