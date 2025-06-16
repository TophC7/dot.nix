{
  config,
  inputs,
  isARM,
  lib,
  pkgs,
  system,
  ...
}:
let
  isCross = pkgs.stdenv.buildPlatform.system != pkgs.stdenv.hostPlatform.system;
in
{
  isoImage = {
    isoName = lib.mkForce "nixos-${config.hostSpec.hostName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
    makeEfiBootable = true;
    makeUsbBootable = true;
    compressImage = false;
    squashfsCompression = lib.mkIf isARM "gzip";
    includeSystemBuildDependencies = lib.mkIf (isARM || isCross) false;
  };

  ## SSH  & NETWORK ##
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  networking = {
    wireless.enable = false;
    networkmanager.enable = true;
    enableIPv6 = false;
  };

  ## PKGS ##
  environment.systemPackages = with pkgs; [
    parted
    gptfdisk
    cryptsetup
    gparted
  ];

  ## VM additions ##
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
  virtualisation.vmware.guest.enable = pkgs.stdenv.hostPlatform.isx86;
  virtualisation.hypervGuest.enable =
    pkgs.stdenv.hostPlatform.isx86 || pkgs.stdenv.hostPlatform.isAarch64;
  services.xe-guest-utilities.enable = pkgs.stdenv.hostPlatform.isx86;
  # The VirtualBox guest additions rely on an out-of-tree kernel module
  # which lags behind kernel releases, potentially causing broken builds.
  virtualisation.virtualbox.guest.enable = false;

  ## System ##
  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = system;
  users.mutableUsers = lib.mkForce true; # Allow password changes

  nixpkgs.config = {
    allowUnsupportedSystem = true;
    allowUnfree = true;
    allowBroken = false;
  };

  systemd.services = lib.mkIf isARM {
    systemd-firstboot.enable = lib.mkForce false;
    systemd-machine-id-commit.enable = lib.mkForce false;
  };
}
