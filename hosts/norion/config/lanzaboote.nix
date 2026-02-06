# Lanzaboote Secure Boot configuration for norion
#
# Prerequisites:
#   1. Keys generated with: sudo sbctl create-keys
#   2. Keys located at /var/lib/sbctl
#   3. After first rebuild, enroll keys with: sudo sbctl enroll-keys --microsoft
#   4. Enable Secure Boot in BIOS/UEFI settings
#
# Verification:
#   - Check signed files: sudo sbctl verify
#   - Check Secure Boot status: bootctl status
#
{ inputs, pkgs, lib, ... }:
{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  environment.systemPackages = [
    # For debugging and troubleshooting Secure Boot
    pkgs.sbctl
  ];

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  # Lanzaboote replaces systemd-boot, so we must disable it
  # Using mkForce since hardware.nix enables it by default
  boot.loader.systemd-boot.enable = lib.mkForce false;
}
