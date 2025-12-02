{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
let
  # Persistent disk (back up with Borg etc.)
  winDisk = "/var/lib/libvirt/images/win11.qcow2";
in
{
  # Ensure images dir exists (permissions for libvirt)
  systemd.tmpfiles.rules = [
    "d /var/lib/libvirt/images 0750 0 0 -"
  ];

  # Declarative Windows 11 VM
  # nixvirt.domains.win11 = {
  #   uuid = "b86198ac-8d30-41d4-ac93-059fe6cbcc79";
  #   title = "Windows 11";
  #   machine.q35 = true;

  #   memory = {
  #     # MiB (locked allocation; change if you later want ballooning)
  #     size = 12288;
  #     backing = {
  #       shared = true;
  #       memfd = true;
  #     };
  #   };

  #   vcpu.count = 12;

  #   firmware = {
  #     type = "uefi";
  #     secureBoot = true;
  #     # tpm true ensures NVRAM + secure boot keys enroll correctly
  #     tpm = true;
  #   };

  #   disks = [
  #     {
  #       target = {
  #         dev = "sda";
  #         bus = "sata";
  #       };
  #       driver = {
  #         name = "qemu";
  #         type = "qcow2";
  #       };
  #       source.file = winDisk;
  #       bootOrder = 1;
  #     }
  #   ];

  #   networks = [
  #     {
  #       network = "vm-lan";
  #       model.type = "e1000e";
  #     }
  #   ];

  #   tpm = {
  #     model = "tpm-tis";
  #     backend = {
  #       type = "emulator";
  #       version = "2.0";
  #     };
  #   };

  #   features = {
  #     acpi = true;
  #     apic = true;
  #     smm = true;
  #     hyperv = {
  #       relaxed = true;
  #       vapic = true;
  #       spinlocks.retries = 8191;
  #       vpindex = true;
  #       runtime = true;
  #       synic = true;
  #       stimer = true;
  #       frequencies = true;
  #       tlbflush = true;
  #       ipi = true;
  #       avic = true;
  #     };
  #   };

  #   cpu = {
  #     mode = "host-passthrough";
  #     check = "none";
  #     migratable = true;
  #   };

  #   graphics = {
  #     type = "spice";
  #     autoport = true;
  #     listen.type = "address";
  #     image.compression = "off";
  #   };

  #   video.model = {
  #     type = "virtio";
  #     heads = 1;
  #     primary = true;
  #   };

  #   audio = {
  #     model = "ich9";
  #     type = "spice";
  #   };

  #   inputs = [
  #     {
  #       type = "tablet";
  #       bus = "usb";
  #     }
  #     {
  #       type = "mouse";
  #       bus = "ps2";
  #     }
  #     {
  #       type = "keyboard";
  #       bus = "ps2";
  #     }
  #   ];

  #   watchdog = {
  #     model = "itco";
  #     action = "reset";
  #   };

  #   balloon.model = "virtio";

  #   onPoweroff = "destroy";
  #   onReboot = "restart";
  #   onCrash = "destroy";
  # };
}
