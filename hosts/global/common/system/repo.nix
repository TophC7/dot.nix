{ config, ... }:
let
  username = config.hostSpec.username;
in
{
  # Create the directories if they do not exist
  systemd.tmpfiles.rules = [
    "d /repo 2775 ${username} ryot -"
  ];

  # Mount the NFS share at /repo
  fileSystems = {
    "/repo" = {
      device = "nimbus:/repo";
      fsType = "nfs";
      options = [
        "_netdev"       # Network device
        "nfsvers=4.2"   # Use NFSv4.2 for best features
        "noatime"       # Don't update access times
        "nofail"        # Don't fail boot if mount fails
        "bg"            # Background mount if server unavailable
        "hard"          # Retry indefinitely on failure
        "intr"          # Allow interruption of operations
      ];
    };
  };

  # Ensure NFS client support is complete
  boot.supportedFilesystems = [ "nfs" ];

  services.nfs.idmapd.settings = {
    General = {
      Domain = "ryot.local"; # Must match on server and client
      Verbosity = 0;
    };
  };
}