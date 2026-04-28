{ lib, ... }:
{
  imports = lib.fs.scanPaths ./.;

  # Newt Networks
  services.newt = {
    extraNetworks = [
      "explorer"
      "pocketbase"
    ];
  };

  # Avoid stacking heavy maintenance jobs at Monday midnight.
  virtualisation.docker.autoPrune = {
    dates = lib.mkForce "Mon *-*-* 02:00:00";
    randomizedDelaySec = lib.mkForce "30min";
  };

  systemd.services.docker-prune.serviceConfig = {
    Nice = 19;
    IOSchedulingClass = "idle";
    IOSchedulingPriority = 7;
  };

  systemd.timers = {
    zfs-snapshot-daily.timerConfig.RandomizedDelaySec = "20min";
    zfs-snapshot-weekly.timerConfig.RandomizedDelaySec = "45min";
    zfs-snapshot-monthly.timerConfig.RandomizedDelaySec = "45min";
  };
}
