{ config, ... }:
let
  username = config.hostSpec.username;
  homeDir = config.hostSpec.home;
in
{
  # Create the directories if they do not exist
  systemd = {
    tmpfiles.rules = [
      "d /pool 2775 ${username} ryot -"
    ];

    services.createGitSymlink = {
      description = "Create symlink from home directory to pool/git";
      after = [
        "network.target"
        "pool.mount"
      ];
      requires = [ "pool.mount" ];
      wantedBy = [ "multi-user.target" ];
      script = ''
        if [ -e ${homeDir}/git ]; then
          echo "Ignoring: ${homeDir}/git already exists"
        else
          ln -sf /pool/git ${homeDir}/git
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };

  # Mount the NFS share at /pool
  fileSystems = {
    "/pool" = {
      device = "cloud:/";
      fsType = "nfs";
      options = [
        "_netdev"
        "defaults"
        "nfsvers=4.2"
        "noacl"
        "noatime"
        "nofail"
        "sec=sys"
      ];
    };
  };

  # Ensure NFS client support is complete
  boot.supportedFilesystems = [ "nfs" ];
  # services.rpcbind.enable = true;

  services.nfs.idmapd.settings = {
    General = {
      Domain = "local"; # Must match on server and client
      Verbosity = 0;
    };
  };
}
