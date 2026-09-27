{
  config,
  host,
  lib,
  pkgs,
  ...
}:
let
  isARM = host.system == "aarch64-linux";
  isCross = pkgs.stdenv.buildPlatform.system != pkgs.stdenv.hostPlatform.system;
in
{
  image.fileName = lib.mkForce "nixos-${host.hostName}-${config.system.nixos.label}-${host.system}.iso";

  isoImage = {
    makeEfiBootable = true;
    makeUsbBootable = true;
    compressImage = false;
    squashfsCompression = lib.mkIf isARM "gzip";
    includeSystemBuildDependencies = lib.mkIf (isARM || isCross) false;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkForce "yes";
      PasswordAuthentication = lib.mkForce true;
    };
  };

  networking = {
    networkmanager.enable = true;
    enableIPv6 = false;
  };

  environment.systemPackages = with pkgs; [
    parted
    gptfdisk
    cryptsetup
    gparted
  ];

  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
  virtualisation.vmware.guest.enable = pkgs.stdenv.hostPlatform.isx86;
  virtualisation.hypervGuest.enable =
    pkgs.stdenv.hostPlatform.isx86 || pkgs.stdenv.hostPlatform.isAarch64;
  services.xe-guest-utilities.enable = pkgs.stdenv.hostPlatform.isx86;
  virtualisation.virtualbox.guest.enable = false;

  system.stateVersion = "25.11";
  boot.zfs.forceImportRoot = false;
  nixpkgs.hostPlatform = host.system;
  users.mutableUsers = lib.mkForce true;

  systemd.services = lib.mkIf isARM {
    systemd-firstboot.enable = lib.mkForce false;
    systemd-machine-id-commit.enable = lib.mkForce false;
  };
}
