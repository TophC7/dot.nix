{
  pkgs,
  ...
}:
{
  imports = [
    ## Required Configs ##
    ../common/core # required

    ## Host-specific Optional Configs ##
    ../common/optional/vscode-server.nix
  ];

  ## Packages with no needed configs ##
  # home.packages = builtins.attrValues {
  #   inherit (pkgs)
  #     ;
  # };
}
