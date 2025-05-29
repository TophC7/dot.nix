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
    (map lib.custom.relativeToRoot [
      "hosts/global/common/system/pool.nix"
    ])
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

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/7ec7d686-6f4c-482f-8b9d-4337a06afc48";
      fsType = "ext4";
    };
  };
  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  # networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp1s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
