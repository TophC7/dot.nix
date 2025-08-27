{
  lib,
  hostSpec,
  ...
}:
{
  imports = [
    (lib.custom.relativeToRoot "home/global/core")
    (lib.custom.relativeToRoot "home/hosts/${hostSpec.hostName}")
  ];
}
