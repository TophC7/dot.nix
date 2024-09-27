{
  programs.fuse.userAllowOther = true;

  fileSystems = {
    "/pool" = {
      device = "toph@104.40.4.24:/pool";
      fsType = "sshfs";
      options = [
        "defaults"
        "reconnect"
        "_netdev"
        "allow_other"
        "identityfile=/home/toph/.ssh/pve"
      ];
    };

    "/home/toph/git" = {
      fsType = "none";
      device = "/pool/git";
      options = ["bind" "nofail"];
    };
  };
}
