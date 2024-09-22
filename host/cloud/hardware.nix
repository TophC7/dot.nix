{
  # for sshfs 
  programs.fuse.userAllowOther = true;

  fileSystems = {
    "/pool" = {
      fsType = "fuse.mergerfs";
      device = "/mnt/data*";
      options = ["direct_io" "defaults" "allow_other" "minfreespace=50G" "fsname=mergerfs" "category.create=mfs" "nonempty"];
    };

    "/var/lib/nextcloud" = {
      fsType = "none";
      device = "/pool/NextCloud";
      options = ["bind" "nofail"];
    };
  };
}
