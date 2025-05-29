{ pkgs, config, ... }:
{
  ## Android Debug Bridge ##
  programs.adb.enable = true;
  users.users.${config.hostSpec.username}.extraGroups = [ "adbusers" ];
}
