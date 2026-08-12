{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    kernelPackages = pkgs.linuxPackages_latest;
    kernel.sysctl."vm.swappiness" = 1;

    initrd = {
      systemd.enable = true;
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "sr_mod"
      ];
    };

    kernelModules = [ "kvm-intel" ];
    supportedFilesystems = [ "btrfs" ];
  };

  hardware = {
    display = {
      edid.packages = [
        (pkgs.runCommand "meowl-edid" { } ''
          mkdir -p $out/lib/firmware/edid
          echo 'AP///////wAF4we0DCcAAAIjAQOAPCJ4DqcVq1BFpigMUFS/7wDRwIGAMWgxfEVoRXxhaGF8al4AoKCgKVAwIDUAVVAhAAAeAAAA/wAxTzBSMUpBMDA5OTk2AAAA/ABDUTI3RzQKICAgICAgAAAA/QwwtA8PSAEKICAgICAgAaoCA0LzTAEDBRQEEx8SAhGQPyMJBweDAQAA4wXjAeYGBwFiYgBtGgAAAgEwtAAAAAAAAGcDDAAQABg8Z9hdxAF4gACY/ABqoKAeUAggNQBVUCEAABpl5wBqoKBnUAggmARVUCEAABpwwgCgoKBVUDAgNQBVUCEAAB4AHgAAAAAA2A==' \
            | base64 -d > $out/lib/firmware/edid/meowl_1440p.bin
        '')
      ];
      outputs."HDMI-A-3" = {
        edid = "meowl_1440p.bin";
        mode = "e";
      };
    };

    intelgpu = {
      computeRuntime = "legacy";
      vaapiDriver = "intel-media-driver";
    };

    nvidia = {
      open = true;
      modesetting.enable = true;
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  programs.fuse.userAllowOther = true;

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/MEOWL";
      fsType = "btrfs";
      options = [
        "subvol=@"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };

    "/home" = {
      device = "/dev/disk/by-label/MEOWL";
      fsType = "btrfs";
      options = [
        "subvol=@home"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };

    "/nix" = {
      device = "/dev/disk/by-label/MEOWL";
      fsType = "btrfs";
      options = [
        "subvol=@nix"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };

    "/var/log" = {
      device = "/dev/disk/by-label/MEOWL";
      fsType = "btrfs";
      options = [
        "subvol=@log"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };

    "/.snapshots" = {
      device = "/dev/disk/by-label/MEOWL";
      fsType = "btrfs";
      options = [
        "subvol=@snapshots"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };

    "/swap" = {
      device = "/dev/disk/by-label/MEOWL";
      fsType = "btrfs";
      options = [
        "subvol=@swap"
        "noatime"
        "ssd"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/MEOWL_BOOT";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 32 * 1024;
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableAllFirmware;
}
