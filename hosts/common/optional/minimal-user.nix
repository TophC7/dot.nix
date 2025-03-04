{ config, ... }:
{
  # Set a temp password for use by minimal builds like installer and iso
  users.users.${config.hostSpec.username} = {
    isNormalUser = true;
    password = config.hostSpec.password;
    extraGroups = [
      "wheel"
      "ryot"
    ];
  };
}
