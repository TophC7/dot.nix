{ config, ... }:
let
  username = config.hostSpec.username;
  homeDir = config.hostSpec.home;
  pve-key = config.secretsSpec.ssh.privateKeys.pve;
in
{
  # For less permission issues with SSHFS
  programs.fuse.userAllowOther = true;

  # Create the directories if they do not exist
  systemd.tmpfiles.rules = [
    "d /pool 2775 ${username} ryot -"
    "d ${homeDir}/git 2775 ${username} ryot -"
  ];

  # File system configuration
  fileSystems = {
    "/pool" = {
      device = "${username}@cloud:/pool";
      fsType = "sshfs";
      options = [
        "defaults"
        "reconnect"
        "_netdev"
        "allow_other"
        "identityfile=${pve-key}"
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
}
