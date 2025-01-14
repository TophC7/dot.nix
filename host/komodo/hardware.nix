{
  admin,
  ...
}:
{
  programs.fuse.userAllowOther = true;

  fileSystems = {
    "/pool" = {
      device = "${admin}@104.40.4.24:/pool";
      fsType = "sshfs";
      options = [
        "defaults"
        "reconnect"
        "_netdev"
        "allow_other"
        "identityfile=/home/${admin}/.ssh/pve"
      ];
    };

    "/home/${admin}/git" = {
      fsType = "none";
      device = "/pool/git";
      options = [
        "bind"
        "nofail"
      ];
    };
  };
}
