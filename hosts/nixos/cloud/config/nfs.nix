{ config, lib, ... }:
{
  # Install and configure NFS server
  services.nfs.server = {
    enable = true;

    exports = ''
      # Pool export - seen as root '/' by the client
      /pool *(rw,insecure,no_subtree_check,no_root_squash,fsid=0,anonuid=1000,anongid=1004)
    '';

    extraNfsdConfig = "vers=4,4.1,4.2";
  };

  # Ensure NFS client support is complete
  # services.rpcbind.enable = true;
  services.nfs.idmapd.settings = {
    General = {
      Domain = "local";
      Verbosity = 0;
    };
  };
}
