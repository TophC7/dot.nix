# Common desktop Home Manager stack.
# Desktop is derived from host role: every non-server gets Niri + DMS.
{ host, lib, ... }:
let
  isDesktop = !(host.isServer or false);
in
{
  imports = lib.optionals isDesktop (lib.fs.scanPaths ./.);
}
