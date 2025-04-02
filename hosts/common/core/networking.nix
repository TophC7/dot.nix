{
  pkgs,
  lib,
  config,
  ...
}:
{
  ## NETWORKING ##
  networking = {
    dhcpcd.enable = false;
    hostName = config.hostSpec.hostName;
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
    useHostResolvConf = false;
    usePredictableInterfaceNames = true;

    hosts = {
      "104.40.3.1" = [ "opn" ];
      "104.40.3.3" = [ "pve" ];
      "104.40.3.24" = [ "cloud" ];
      "104.40.3.34" = [ "proxy" ];
      "104.40.3.44" = [ "komodo" ];
      "104.40.3.54" = [ "nix" ];
      "104.40.4.1" = [ "opn" ];
      "104.40.4.7" = [ "rune" ];
    };
  };
}
