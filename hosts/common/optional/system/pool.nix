{ config, ... }:
let
  username = config.hostSpec.username;
  homeDir = config.hostSpec.home;
in
{
  # Create the directories if they do not exist
  systemd.tmpfiles.rules = [
    "d /pool 2775 ${username} ryot -"
    "d ${homeDir}/git 2775 ${username} ryot -"
  ];

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

    "${homeDir}/git" = {
      fsType = "none";
      device = "/pool/git";
      options = [
        "bind"
        "nofail"
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
