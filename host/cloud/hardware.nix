{
  admin,
  ...
}:
{
  # for sshfs
  programs.fuse.userAllowOther = true;

  fileSystems = {
    "/pool" = {
      fsType = "fuse.mergerfs";
      device = "/mnt/data*";
      options = [
        "direct_io"
        "defaults"
        "allow_other"
        "minfreespace=50G"
        "fsname=mergerfs"
        "category.create=mfs"
        "nonempty"
        "uid=1000"
        "gid=1004" # Ryot group
        "umask=002"
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

    # "/var/lib/nextcloud" = {
    #   fsType = "none";
    #   device = "/pool/NextCloud";
    #   options = [
    #     "bind"
    #     "nofail"
    #   ];
    # };
  };
}
