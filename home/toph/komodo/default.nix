{
  pkgs,
  ...
}:
{
  imports = [
    ## Required Configs ##
    ../common/core # required

    ## Host-specific Optional Configs ##
  ];

  # Useful for this host
  home.file = {
    Pool.source = config.lib.file.mkOutOfStoreSymlink "/pool";
    DockerStorage.source = config.lib.file.mkOutOfStoreSymlink "/mnt/DockerStorage";
  };

  ## Packages with no needed configs ##
  # home.packages = builtins.attrValues {
  #   inherit (pkgs)
  #     ;
  # };
}
