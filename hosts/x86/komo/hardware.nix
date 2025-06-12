{
  lib,
  ...
}:
{
  imports = lib.flatten [
    (map lib.custom.relativeToRoot [
      "hosts/global/common/system/lxc.nix"
      "hosts/global/common/system/pool.nix"
    ])
  ];

  ## Easy links, I use this dirs more often in this host
  systemd.user.tmpfiles.rules = [
    "L+ %h/Pool - - - - /pool"
    "L+ %h/DockerStorage - - - - /mnt/DockerStorage"
  ];
}
