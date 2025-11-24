{ pkgs, lib, ... }:
{
  # GTK Bookmarks for Nautilus sidebar
  xdg.configFile."gtk-3.0/bookmarks".text = ''
    file:///repo 🪑 Repo
    file:///fast ⚡ Fast
    file:///tank 🫙 Tank
    file:///store 🐳 Store
    file:///home/toph/Documents
    file:///home/toph/Downloads
    file:///home/toph/Games Games
    file:///home/toph/Pictures
  '';

  # Custom folder icons using theme-aware icon names
  # These will follow your GTK icon theme automatically
  home.activation.setNautilusFolderIcons = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Only set icons if directories exist to avoid errors
    [[ -d /steam ]] && ${pkgs.glib}/bin/gio set /steam metadata::custom-icon-name "folder-steam" || true
    [[ -d $HOME/Games ]] && ${pkgs.glib}/bin/gio set $HOME/Games metadata::custom-icon-name "folder-games" || true
    [[ -d /repo ]] && ${pkgs.glib}/bin/gio set /repo metadata::custom-icon-name "folder-git" || true
    [[ -d /tank ]] && ${pkgs.glib}/bin/gio set /tank metadata::custom-icon-name "folder-cd" || true
    [[ -d /store ]] && ${pkgs.glib}/bin/gio set /store metadata::custom-icon-name "folder-docker" || true
    [[ -d /fast ]] && ${pkgs.glib}/bin/gio set /fast metadata::custom-icon-name "folder-development" || true
  '';
}
