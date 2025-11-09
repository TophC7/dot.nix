{
  lib,
  host,
  pkgs,
  ...
}:
{
  imports = [
    (lib.custom.relativeToRoot "home/global/core")
    (lib.optionalAttrs (!host.isServer) ./theme)
    (lib.custom.relativeToRoot "home/hosts/${host.network.hostName}")
  ];
}
