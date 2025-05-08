# Add your reusable NixOS modules to this directory, on their own file (https://wiki.nixos.org/wiki/NixOS_modules).
# These are modules you would share with others, not your personal configurations.

{ lib, ... }:
{
  # Imports all NixOS modules found in the current directory.
  # `lib.custom.scanPaths ./.` scans the current directory (./) for NixOS modules and imports them.
  imports = lib.custom.scanPaths ./.;
}
