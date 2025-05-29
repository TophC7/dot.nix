# Add your reusable NixOS or Home-Manger modules to this directory, on their own file (https://wiki.nixos.org/wiki/NixOS_modules).
# These are modules you would share with others, not your specific configurations.
{ lib, ... }:
{
  imports = lib.custom.scanPaths ./.;
}
