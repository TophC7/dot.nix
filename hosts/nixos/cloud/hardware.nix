{
  lib,
  config,
  ...
}:
let
  username = config.hostSpec.username;
  homeDir = config.hostSpec.home;
in
{
  imports = lib.flatten [
    (map lib.custom.relativeToRoot [
      "hosts/global/common/system/lxc.nix"
    ])
  ];

  # Less permission issues with pool
  programs.fuse.userAllowOther = true;

  # INFO: Cloud is the pool provider
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
        "nfsopenhack=all"
        "nonempty"
        "uid=1000"
        "gid=1004" # Ryot group
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
