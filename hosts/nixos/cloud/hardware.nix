{
  lib,
  ...
}:
{
  imports = lib.flatten [
    (map lib.custom.relativeToRoot [
      "hosts/common/optional/system/lxc.nix"
      "hosts/common/optional/system/pool.nix"
    ])
  ];
}
