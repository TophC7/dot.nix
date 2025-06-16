{
  config,
  inputs,
  isARM,
  lib,
  pkgs,
  system,
  ...
}:
{
  # ISO settings
  isoImage = {
    isoName = lib.mkForce "nixos-${config.hostSpec.hostName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
    makeEfiBootable = true;
    makeUsbBootable = true;
    compressImage = false;
  };

  # Enable root SSH access
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

  # Extra pkgs; iso tools
  environment.systemPackages = with pkgs; [
    parted
    gptfdisk
    cryptsetup
    gparted
  ];

  # VM guest additions to improve host-guest interaction
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
  virtualisation.vmware.guest.enable = pkgs.stdenv.hostPlatform.isx86;
  # https://github.com/torvalds/linux/blob/00b827f0cffa50abb6773ad4c34f4cd909dae1c8/drivers/hv/Kconfig#L7-L8
  virtualisation.hypervGuest.enable =
    pkgs.stdenv.hostPlatform.isx86 || pkgs.stdenv.hostPlatform.isAarch64;
  services.xe-guest-utilities.enable = pkgs.stdenv.hostPlatform.isx86;
  # The VirtualBox guest additions rely on an out-of-tree kernel module
  # which lags behind kernel releases, potentially causing broken builds.
  virtualisation.virtualbox.guest.enable = false;

  # Basic system settings
  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = system;
  nixpkgs.config.allowUnsupportedSystem = true; # Cross-compilation
  users.mutableUsers = lib.mkForce true; # Allow password changes
}
