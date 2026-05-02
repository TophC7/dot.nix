{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  affinityPkgs = pkgs.extend inputs.affinity-nix.overlays.default;
in
{
  assertions = [
    {
      assertion = system == "x86_64-linux";
      message = "affinity-nix only supports x86_64-linux.";
    }
  ];

  home.packages = lib.optionals (system == "x86_64-linux") [
    affinityPkgs.affinity-v3
  ];
}
