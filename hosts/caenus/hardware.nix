{
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  ## Boot ##
  boot = {
    loader = {
      systemd-boot.enable = true;
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
    kernelParams = [ "net.ifnames=0" ];
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/467be3e2-75cb-439f-8255-e1ed3a00c2d8";
    fsType = "ext4";
  };

  fileSystems."/storage" = {
    device = "/dev/disk/by-uuid/a3666a64-591c-45ab-8393-3dd1a0a51d79";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/E12E-D69C";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  # networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp1s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
