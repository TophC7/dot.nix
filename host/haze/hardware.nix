{
  config,
  lib,
  pkgs,
  modulesPath,
  admin,
  ...
}:
{

  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.kernelModules = [
    "kvm-amd"
    "i2c-dev"
  ];

  # for ddcutil to work
  hardware.i2c.enable = true;
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';

  programs.fuse.userAllowOther = true;

  fileSystems = {
    # "/" = {
    #   device = "/dev/disk/by-uuid/28a9ac4d-1e87-4731-9c06-916711d83cb2";
    #   fsType = "ext4";
    # };

    # "/boot" = {
    #   device = "/dev/disk/by-uuid/B182-E50E";
    #   fsType = "vfat";
    #   options = [
    #     "fmask=0077"
    #     "dmask=0077"
    #   ];
    # };

    "/pool" = {
      device = "${admin}@104.40.4.24:/pool";
      fsType = "sshfs";
      options = [
        "defaults"
        "reconnect"
        "_netdev"
        "allow_other"
        "identityfile=/home/${admin}/.ssh/pve"
      ];
    };

    "/home/${admin}/git" = {
      fsType = "none";
      device = "/pool/git";
      options = [
        "bind"
        "nofail"
      ];
    };
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/81b6fa27-af94-41d4-9070-8754087a4c26"; } ];

  networking.useDHCP = lib.mkDefault true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
