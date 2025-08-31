{ pkgs, ... }:
{
  # BTRFS utilities and maintenance tools
  environment.systemPackages = with pkgs; [
    btrfs-progs
    compsize  # Check compression ratio
    btrbk     # Backup tool for BTRFS
  ];

  # Create necessary directories for bind mounts
  systemd.tmpfiles.rules = [
    "d /store/lib/docker 0755 root root -"
    "d /store/lib/lxc 0755 root root -"
  ];

  # BTRFS maintenance script example
  systemd.services.btrfs-snapshot-before-update = {
    description = "Create BTRFS snapshot before system update";
    path = [ pkgs.btrfs-progs ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'btrfs subvolume snapshot -r / /.snapshots/pre-update-$(date +%Y%m%d-%H%M%S)'";
    };
  };
}