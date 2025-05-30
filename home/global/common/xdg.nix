{
  pkgs,
  config,
  ...
}:
let
  # FIXME: Should use config options and just reference whatever is configured as the default
  files = [ "org.gnome.Nautilus.desktop" ];
  browser = [ "zen.desktop" ];
  editor = [ "code.desktop" ];
  steam = [ "steam-session.desktop" ];
  # Extensive list of associations here:
  # https://github.com/iggut/GamiNiX/blob/8070528de419703e13b4d234ef39f05966a7fafb/system/desktop/home-main.nix#L77
  associations = {
    "x-scheme-handler/steam" = steam;
    "x-scheme-handler/steamlink" = steam;

    "inode/directory" = files;

    "text/*" = editor;
    "text/plain" = editor;

    # "text/html" = browser;
    "application/x-zerosize" = editor; # empty files

    "application/x-shellscript" = editor;
    "application/x-perl" = editor;
    "application/json" = editor;
    "application/x-extension-htm" = browser;
    "application/x-extension-html" = browser;
    "application/x-extension-shtml" = browser;
    "application/xhtml+xml" = browser;
    "application/x-extension-xhtml" = browser;
    "application/x-extension-xht" = browser;
    "application/pdf" = browser;

    "x-scheme-handler/http" = browser;
    "x-scheme-handler/https" = browser;

    "image/*" = browser;
  };

in
{
  # Enables app shorcuts
  targets.genericLinux.enable = true;
  xdg.mime.enable = true;
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = associations;
  xdg.mimeApps.associations.added = associations;
  xdg.systemDirs.data = [ "${config.home.homeDirectory}/.nix-profile/share/applications" ];

  home.packages = builtins.attrValues {
    inherit (pkgs)
      handlr-regex # better xdg-open for desktop apps
      ;
  };

}
