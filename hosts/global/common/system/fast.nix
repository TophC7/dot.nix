{ config, ... }:
let
  username = config.hostSpec.username;
  homeDir = config.hostSpec.home;
in
{
  # Create the directories if they do not exist
  systemd = {
    tmpfiles.rules = [
      "d /fast 2775 ${username} ryot -"
    ];

    services.createGitSymlink = {
      description = "Create symlink from home directory to fast/git";
      after = [
        "network.target"
        "fast.mount"
      ];
      requires = [ "fast.mount" ];
      wantedBy = [ "multi-user.target" ];
      script = ''
        if [ -e ${homeDir}/git ]; then
          echo "Ignoring: ${homeDir}/git already exists"
        else
          ln -sf /fast/git ${homeDir}/git
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };

  # Mount the NFS share at /fast
  fileSystems = {
    "/fast" = {
      device = "nimbus:/fast";
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