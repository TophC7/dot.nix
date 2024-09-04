{
  # Treats the system as a container.
  boot.isContainer = true;

  programs.fuse.userAllowOther = true;

  fileSystems."/pool" = {
    fsType = "fuse.mergerfs";
    device = "/mnt/data*";
    options = ["direct_io" "defaults" "allow_other" "minfreespace=50G" "fsname=mergerfs" "category.create=mfs" "nonempty"];
  };

  # Set your system kind (needed for flakes)
  nixpkgs.hostPlatform = "x86_64-linux";
}
