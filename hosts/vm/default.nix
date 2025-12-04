###############################################################
#
#  VM - Testing Virtual Machine
#  NixOS running in VM
#
###############################################################

{
  flakeRoot,
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    ## VM Specific Imports ##
    (lib.fs.scanPaths ./.)

    ## Additional Configs ##
    (map (lib.fs.relativeTo flakeRoot) [
      "modules/hosts/common/plymouth.nix" # fancy boot screen
    ])
  ];

  networking = {
    enableIPv6 = false;
  };

  # VM guest additions to improve host-guest interaction
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
  virtualisation.vmware.guest.enable = pkgs.stdenv.hostPlatform.isx86;
  virtualisation.hypervGuest.enable = true;
  # The VirtualBox guest additions rely on an out-of-tree kernel module
  # which lags behind kernel releases, potentially causing broken builds.
  virtualisation.virtualbox.guest.enable = false;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
