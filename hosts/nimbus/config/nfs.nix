{ config, lib, ... }:
{
  services.nfs.server = {
    enable = true;

    # NOTE: /repo uses 'sync' for Nix flake consistency (prevents stale flake.lock reads)
    # /tank and /fast use 'async' for performance (media/data, not critical for consistency)
    exports = ''
      # Export ZFS tank dataset (media/data - async OK)
      /tank *(rw,insecure,no_subtree_check,no_root_squash,fsid=1,anonuid=1000,anongid=1004,async,no_wdelay)
      # Export ZFS fast dataset (scratch/data - async OK)
      /fast *(rw,insecure,no_subtree_check,no_root_squash,fsid=2,anonuid=1000,anongid=1004,async,no_wdelay)
      # Export ZFS repo dataset (Nix configs - sync required for consistency)
      /repo *(rw,insecure,no_subtree_check,no_root_squash,fsid=3,anonuid=1000,anongid=1004,sync)
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
