# Shared home-manager desktop configuration
# Loads DE-specific configs based on hostSpec
{
  config,
  host,
  lib,
  ...
}:
{
  imports = lib.flatten [
    (lib.optional (host.gnome or false) ./gnome)
    (lib.optional (host.niri or false) ./niri)
    ./ghostty.nix
    ./theme.nix
  ];

  # Shared desktop configs can go here
}
