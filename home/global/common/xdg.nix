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
  steam = [ "steam.desktop" ];
  heroic = [ "com.heroicgameslauncher.hgl.desktop" ];
  archive = [ "org.gnome.FileRoller.desktop" ];
  pdfViewer = [ "org.gnome.Papers.desktop" ];
  imageViewer = [ "org.gnome.Loupe.desktop" ];

  # Extensive list of associations here:
  # https://github.com/iggut/GamiNiX/blob/8070528de419703e13b4d234ef39f05966a7fafb/system/desktop/home-main.nix#L77
  associations = {
    "x-scheme-handler/steam" = steam;
    "x-scheme-handler/steamlink" = steam;
    "x-scheme-handler/heroic" = heroic;

    "inode/directory" = files;

    # Text and coding file types
    "text/*" = editor;
    "text/plain" = editor;
    "text/x-authors" = editor;
    "text/x-changelog" = editor;
    "text/x-copying" = editor;
    "text/x-install" = editor;
    "text/x-license" = editor;
    "text/x-log" = editor;
    "text/x-makefile" = editor;
    "text/x-readme" = editor;

    # Configuration files
    "application/javascript" = editor;
    "application/json" = editor;
    "application/toml" = editor;
    "application/typescript" = editor;
    "application/x-desktop" = editor;
    "application/x-perl" = editor;
    "application/x-python" = editor;
    "application/x-ruby" = editor;
    "application/x-shellscript" = editor;
    "application/x-wine-extension-ini" = editor;
    "application/x-yaml" = editor;
    "application/xml" = editor;
    "application/yaml" = editor;

    # Development files
    "text/css" = editor;
    "text/html" = editor;
    "text/markdown" = editor;
    "text/x-c++hdr" = editor;
    "text/x-c++src" = editor;
    "text/x-chdr" = editor;
    "text/x-csrc" = editor;
    "text/x-go" = editor;
    "text/x-java" = editor;
    "text/x-markdown" = editor;
    "text/x-nix" = editor;
    "text/x-php" = editor;
    "text/x-python" = editor;
    "text/x-ruby" = editor;
    "text/x-rust" = editor;
    "text/x-script.python" = editor;

    # Config and dotfiles
    "text/x-cmake" = editor;
    "text/x-dockerfile" = editor;
    "application/x-subrip" = editor;

    # Special files
    "application/x-zerosize" = editor; # empty files

    # Web content
    "application/x-extension-htm" = browser;
    "application/x-extension-html" = browser;
    "application/x-extension-shtml" = browser;
    "application/x-extension-xht" = browser;
    "application/x-extension-xhtml" = browser;
    "application/xhtml+xml" = browser;
    "x-scheme-handler/http" = browser;
    "x-scheme-handler/https" = browser;

    # PDF files
    "application/pdf" = pdfViewer;

    # Image formats
    "image/*" = imageViewer;
    "image/bmp" = imageViewer;
    "image/gif" = imageViewer;
    "image/jpeg" = imageViewer;
    "image/png" = imageViewer;
    "image/svg+xml" = imageViewer;
    "image/tiff" = imageViewer;
    "image/vnd.microsoft.icon" = imageViewer;
    "image/webp" = imageViewer;
    "image/x-icon" = imageViewer;

    # Archive formats
    "application/gzip" = archive;
    "application/vnd.rar" = archive;
    "application/x-7z-compressed" = archive;
    "application/x-ace" = archive;
    "application/x-archive" = archive;
    "application/x-arj" = archive;
    "application/x-bzip-compressed-tar" = archive;
    "application/x-bzip2" = archive;
    "application/x-compress" = archive;
    "application/x-compressed-tar" = archive;
    "application/x-compressed" = archive;
    "application/x-cpio" = archive;
    "application/x-deb" = archive;
    "application/x-gtar" = archive;
    "application/x-gzip" = archive;
    "application/x-iso9660-image" = archive;
    "application/x-lz4" = archive;
    "application/x-lzip" = archive;
    "application/x-lzma-compressed-tar" = archive;
    "application/x-lzma" = archive;
    "application/x-rar-compressed" = archive;
    "application/x-rar" = archive;
    "application/x-rpm" = archive;
    "application/x-tar" = archive;
    "application/x-xz-compressed-tar" = archive;
    "application/x-xz" = archive;
    "application/x-zip-compressed" = archive;
    "application/x-zstd-compressed-tar" = archive;
    "application/zip" = archive;
    "application/zstd" = archive;
  };
in
{
  # Enables app shortcuts
  targets.genericLinux.enable = true;

  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];
    };

    mime.enable = true;
    mimeApps.enable = true;
    mimeApps.defaultApplications = associations;
    mimeApps.associations.added = associations;
    systemDirs.data = [ "${config.home.homeDirectory}/.nix-profile/share/applications" ];
  };

  home.packages = builtins.attrValues {
    inherit (pkgs)
      handlr-regex # better xdg-open for desktop apps
      ;
  };

}
