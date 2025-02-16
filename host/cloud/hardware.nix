{
  admin,
  ...
}:
{
  # for sshfs
  programs.fuse.userAllowOther = true;

  # TODO: use tempfls to set the acls in nix config
  fileSystems = {
    "/pool" = {
      fsType = "fuse.mergerfs";
      device = "/mnt/data*";
      options = [
        "cache.files=auto-full"
        "defaults"
        "allow_other"
        "minfreespace=50G"
        "fsname=mergerfs"
        "category.create=mfs"
        "nonempty"
        "uid=1000"
        "gid=1004" # Ryot group
        "posix_acl=true"
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
