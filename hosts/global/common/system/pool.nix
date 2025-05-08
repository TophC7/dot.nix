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
        umount /pool/git
        mkdir -p /pool/git
        chown ${username}:ryot /pool/git
        chmod 2775 /pool/git
        ln -sf /pool/git ${homeDir}/git
        chown -h ${username}:ryot ${homeDir}/git
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };

  # File system configuration
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

  # Optional: Configure ID mapping if needed
  services.nfs.idmapd.settings = {
    General = {
      Domain = "local"; # Must match on server and client
      Verbosity = 0;
    };
  };
}
