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
      "hosts/common/optional/system/lxc.nix"
    ])
  ];

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
        "nonempty"
        "uid=1000"
        "gid=1004" # Ryot group
        "posix_acl=true"
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
