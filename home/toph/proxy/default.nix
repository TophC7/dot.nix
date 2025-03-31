{
  pkgs,
  ...
}:
{
  imports = [
    ## Required Configs ##
    ../common/core # required
  ];

  ## Packages with no needed configs ##
  # home.packages = builtins.attrValues {
  #   inherit (pkgs)
  #     ;
  # };
}
