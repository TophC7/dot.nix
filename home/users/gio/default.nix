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
}
