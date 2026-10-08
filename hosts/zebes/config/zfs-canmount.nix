{
  config,
  lib,
  pkgs,
  ...
}:

{
  systemd.services.zfs-enforce-canmount = {
    description = "Reserve store/store mounting for store.mount";
    requires = [ "zfs-import-store.service" ];
    after = [ "zfs-import-store.service" ];
    before = [
      "zfs-mount.service"
      "store.mount"
    ];
    # Both mount paths must wait for successful enforcement, not merely request it.
    requiredBy = [
      "zfs-mount.service"
      "store.mount"
    ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeScript "zfs-enforce-canmount" ''
        #!${lib.getExe pkgs.fish}
        exec ${lib.getExe' config.boot.zfs.package "zfs"} set canmount=noauto store/store
      '';
    };
  };
}
