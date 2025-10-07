{
  pkgs,
  config,
  host,
  ...
}:
{
  ## Android Debug Bridge ##
  programs.adb.enable = true;
  users.users.${host.user.name}.extraGroups = [ "adbusers" ];
}
