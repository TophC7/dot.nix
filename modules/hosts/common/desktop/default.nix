# Common desktop host stack.
# Non-server hosts get the desktop stack; servers stay headless.
{ host, lib, ... }:
{
  imports = lib.optionals (!(host.isServer or false)) (lib.fs.scanPaths ./.);
}
