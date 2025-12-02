# Shared home-manager desktop configuration
# Loads DE-specific configs based on host.desktop
#
# With mix.nix, host.desktop is a string (e.g., "gnome", "niri") or null.
#
{
  host,
  lib,
  inputs,
  ...
}:
{
  imports = lib.flatten [
    inputs.mix-nix.homeManagerModules.monitors
    (lib.optional (host.desktop == "gnome") ./gnome)
    (lib.optional (host.desktop == "niri") ./niri)
    ./shared
  ];
}
