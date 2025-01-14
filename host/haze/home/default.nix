{
  pkgs,
  zen,
  config,
  ...
}:
{
  # Module imports
  imports = [
    # Common Modules
    ../../../common/home
    # ../../../common/git
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
    inspector
    monocraft
    nerd-fonts.fira-code
    nodejs_22
    pnpm
    prettierd
    prismlauncher
    spotify
    telegram-desktop
    vesktop
    zen
  ];
}
