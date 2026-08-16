###############################################################
#
#  Meowl - Dell OptiPlex 3080
#
#  Intel Core i5-10505, UHD Graphics 630, 32GB RAM
#
###############################################################

{
  flakeRoot,
  inputs,
  lib,
  ...
}:
{
  imports = lib.flatten [
    (lib.fs.scanPaths ./.)
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
    (map (lib.fs.relativeTo flakeRoot) [
      "modules/hosts/common/gaming.nix"
      "modules/hosts/common/docker.nix"
      "modules/hosts/common/pangolin/newt.nix"
    ])
  ];

  play.amd.enable = lib.mkForce false;

  networking.enableIPv6 = false;
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
