# FIXME: FIX to hardware.fix once out of VM, this is TEMP vm hardware config
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  username = config.hostSpec.username;
in
{
  imports = lib.flatten [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  ## Boot ##
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/vda";
        useOSProber = true;
      };
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    # use latest kernel
    kernelPackages = pkgs.linuxPackages_latest;

    initrd = {
      availableKernelModules = [
        "ahci"
        "xhci_pci"
        "virtio_pci"
        "sr_mod"
        "virtio_blk"
      ];
      systemd.enable = true;
      verbose = false;
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/5f1ad3a9-18ce-42ab-83ea-b67bccaa6972";
    fsType = "ext4";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/e3fc8d25-31a5-48c1-8c81-c6c237f671bb"; }
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  # networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp1s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
