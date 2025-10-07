{
  lib,
  host,
  ...
}:
{
  imports = [
    (lib.custom.relativeToRoot "home/global/core")
    (lib.custom.relativeToRoot "home/hosts/${host.network.hostName}")
  ];
}
