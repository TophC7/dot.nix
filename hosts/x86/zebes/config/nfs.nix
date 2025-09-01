{ config, lib, ... }:
{
  services.nfs.server = {
    enable = true;

    exports = ''
      # Export ZFS store dataset
      /store *(rw,insecure,no_subtree_check,no_root_squash,fsid=4,anonuid=1000,anongid=1004,async,no_wdelay)
    '';

    extraNfsdConfig = "vers=4,4.1,4.2";
  };

  # Ensure NFS client support is complete
  # services.rpcbind.enable = true;
  services.nfs.idmapd.settings = {
    General = {
      Domain = "ryot.local";
      Verbosity = 0;
    };
  };
}