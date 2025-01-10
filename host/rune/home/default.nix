{ pkgs, zen, config, ... }:
{
  # Module imports
  imports = [
    # Common Modules
    ../../../common/home
    ../../../common/git
    ../../../common/vscode

    # Modules
    ../modules/gnome/home.nix
  ];

  # Enables app shorcuts
  targets.genericLinux.enable = true;
  xdg.mime.enable = true;
  xdg.systemDirs.data = [ "${config.home.homeDirectory}/.nix-profile/share/applications" ];

  home.packages = with pkgs; [
    chafa
    fastfetch
    fish
    fishPlugins.grc
    fishPlugins.tide
    grc
    nodejs_22
    pnpm
    prettierd
    spotify
    telegram-desktop
    vesktop
    zen
  ];
}
