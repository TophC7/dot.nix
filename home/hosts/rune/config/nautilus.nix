{ config, inputs, ... }:
{
  imports = [ inputs.mix-nix.homeManagerModules.nautilus ];
  programs.nautilus = {
    enable = true;

    bookmarks = [
      {
        path = "/fast";
        name = "⚡ Fast";
      }
      {
        path = "/repo/Nix";
        name = "❄️ Nix";
      }
      {
        path = "/repo";
        name = "🪑 Repo";
      }
      {
        path = "/store";
        name = "🐳 Store";
      }
      {
        path = "/tank";
        name = "🫙 Tank";
      }
      { path = "${config.home.homeDirectory}/Documents"; }
      { path = "${config.home.homeDirectory}/Downloads"; }
      {
        path = "${config.home.homeDirectory}/Games";
        name = "Games";
      }
      { path = "${config.home.homeDirectory}/Pictures"; }
    ];

    folderIcons = {
      "/fast" = "folder-development";
      "/repo" = "folder-git";
      "/repo/Nix" = "folder-linux";
      "/steam" = "folder-steam";
      "/store" = "folder-docker";
      "/tank" = "folder-cd";
      "${config.home.homeDirectory}/Games" = "folder-games";
    };
  };
}
