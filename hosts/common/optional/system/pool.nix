{ config, ... }:
{
  # For less permission issues with SSHFS
  programs.fuse.userAllowOther = true;

  # Create the directories if they do not exist
  systemd.tmpfiles.rules = [
    "d /pool 2775 ${config.hostSpec.username} ryot -"
    "d /home/${config.hostSpec.username}/git 2775 ${config.hostSpec.username} ryot -"
  ];

  # File system configuration
  fileSystems = {
    "/pool" = {
      device = "${config.hostSpec.username}@cloud:/pool";
      fsType = "sshfs";
      options = [
        "defaults"
        "reconnect"
        "_netdev"
        "allow_other"
        "identityfile=/home/${config.hostSpec.username}/.ssh/pve"
      ];
    };

    "/home/${config.hostSpec.username}/git" = {
      fsType = "none";
      device = "/pool/git";
      options = [
        "bind"
        "nofail"
      ];
    };
  };
}
