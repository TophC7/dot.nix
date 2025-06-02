{
  lib,
  config,
  ...
}:
let
  username = config.hostSpec.username;
in
{
  imports = lib.flatten [
    (map lib.custom.relativeToRoot [
      "hosts/global/common/system/lxc.nix"
      "hosts/global/common/system/pool.nix"
    ])
  ];

  # Ochre has no access to PVE DockerStorage, so sock will have its own storage
  systemd.user.tmpfiles.rules = [
    "d /OchreStorage 2775 ${username} ryot -"
  ];
}
