{ config, ... }:
let
  hostSpec = config.hostSpec;
in
{

  users.groups = {
    ryot = {
      gid = 1004;
      members = [ "${hostSpec.username}" ];
    };
  };

  # Set a temp password for use by minimal builds like installer and iso
  users.users.${hostSpec.username} = {
    isNormalUser = true;
    hashedPassword = hostSpec.hashedPassword;
    group = "ryot";
    extraGroups = [
      "wheel"
    ];
  };
}
