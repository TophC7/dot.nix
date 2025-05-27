{
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    ## Common Imports ##
    (map lib.custom.relativeToRoot [
      "home/global/common/vscode-server.nix"
    ])

    ## Nix Specific ##
    # ./config
  ];

  ## Packages with no needed configs ##
  home.packages = builtins.attrValues {
    inherit (pkgs)
      chafa
      nodejs
      pnpm
      # x2goserver
      ;
  };
}
