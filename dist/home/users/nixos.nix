{
  host,
  lib,
  ...
}:
{
  imports = lib.optionals (!host.isServer) [ ./theme ];
}
