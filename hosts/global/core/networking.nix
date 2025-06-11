{
  pkgs,
  lib,
  config,
  ...
}:
{
  networking = {
    dhcpcd.enable = false;
    hostName = config.hostSpec.hostName;
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
    useHostResolvConf = false;
    usePredictableInterfaceNames = true;
  };
}
