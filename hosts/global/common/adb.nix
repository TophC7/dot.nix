{ pkgs, config, ... }:
{
  programs.adb.enable = true;
  users.users.${config.hostSpec.username}.extraGroups = [ "adbusers" ];
}
