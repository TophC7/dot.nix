{
  config,
  ...
}:
{

  home.file = {
    Pool.source = config.lib.file.mkOutOfStoreSymlink "/pool";
    DockerStorage.source = config.lib.file.mkOutOfStoreSymlink "/mnt/DockerStorage";
  };
}
