{ config, ... }:
let
  username = config.hostSpec.username;
in
{
  # Create the directories if they do not exist
  systemd.tmpfiles.rules = [
    "d /tank 2775 ${username} ryot -"
  ];

  # Mount the NFS share at /tank using systemd
  systemd.mounts = [
    {
      enable = true;
      what = "nimbus:/tank";
      where = "/tank";
      type = "nfs";
      options = "nfsvers=4.2,noatime,hard,intr";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      unitConfig = {
        TimeoutSec = "30";
      };
      mountConfig = {
        TimeoutSec = "30";
      };
    }
  ];

  systemd.automounts = [
    {
      enable = true;
      where = "/tank";
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
    }
  ];

  # Ensure NFS client support is complete
  boot.supportedFilesystems = [ "nfs" ];

  services.nfs.idmapd.settings = {
    General = {
      Domain = "ryot.local"; # Must match on server and client
      Verbosity = 0;
    };
  };
}