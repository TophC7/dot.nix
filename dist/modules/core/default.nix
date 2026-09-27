# ISO core - applied after dot.nix's modules/core (mix.extends = dotNixRoot)
#
# Every ISO host gets the minimal installer, the shared ISO settings, and the
# server or desktop variant selected by host.isServer.
{ host, inputs, ... }:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    ./iso.nix
    (if host.isServer then ./server.nix else ./desktop.nix)
  ];
}
