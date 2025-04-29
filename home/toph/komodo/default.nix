{
  pkgs,
  config,
  ...
}:
{
  imports = [
    ## Required Configs ##
    ../common/core # required
  ];

  home.file = {
    Pool.source = config.lib.file.mkOutOfStoreSymlink "/pool";
    DockerStorage.source = config.lib.file.mkOutOfStoreSymlink "/mnt/DockerStorage";
  };
}
