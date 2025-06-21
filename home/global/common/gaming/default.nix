{
  pkgs,
  lib,
  ...
}:
{
  imports = lib.custom.scanPaths ./.;

  home.packages = with pkgs; [
    prismlauncher
    # modrinth-app
  ];
}
