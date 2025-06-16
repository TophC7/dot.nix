{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  imports = [
    "${inputs.dot-nix}/home/global/core"
    "${inputs.dot-nix}/home/global/common/gnome"
    "${inputs.dot-nix}/home/global/common/vscode"
    "${inputs.dot-nix}/home/global/common/xdg.nix"
    "${inputs.dot-nix}/home/global/common/zen.nix"
    ./theme
  ];
}
