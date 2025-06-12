{
  lib,
  config,
  pkgs,
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
  systemd.tmpfiles.rules = [
    # Create directory with setgid bit and proper ownership
    "d /OchreStorage 2775 1000 1004 -"
  ];

  # Use systemd service to ensure proper permissions with ACLs
  systemd.services.ochre-storage-permissions = {
    description = "Set proper permissions for OchreStorage";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    path = with pkgs; [
      acl
      coreutils
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Ensure directory exists and has correct ownership/permissions
      mkdir -p /OchreStorage
      chown 1000:1004 /OchreStorage
      chmod 2775 /OchreStorage

      # Set default ACLs to ensure all new files/folders inherit 1000:1004
      setfacl -d -m u:1000:rwx /OchreStorage
      setfacl -d -m g:1004:rwx /OchreStorage
    '';
  };

  environment.systemPackages = with pkgs; [ acl ];
}
