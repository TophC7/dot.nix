{
  pkgs,
  config,
  host,
  ...
}:
{
  ## Android Debug Bridge ##
  environment.systemPackages = [ pkgs.android-tools ];
  users.users.${host.user.name}.extraGroups = [ "adbusers" ];
}
