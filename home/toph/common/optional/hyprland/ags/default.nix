{ inputs, pkgs, ... }:
let
  extraPkgs = with pkgs; [
    fzf
  ];

  agsPkgs = with inputs.ags.packages.${pkgs.system}; [
    apps
    bluetooth
    greet
    hyprland
    mpris
    network
    notifd
    tray
    wireplumber
  ];
in
{
  imports = [ inputs.ags.homeManagerModules.default ];

  home.packages = [ inputs.astal.packages.${pkgs.system}.default ] ++ extraPkgs;

  programs.ags = {
    enable = true;

    configDir = ../ags;

    # additional packages to add to gjs's runtime
    extraPackages = extraPkgs ++ agsPkgs;
  };
}
