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
}
