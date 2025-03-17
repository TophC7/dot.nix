{
  config,
  pkgs,
  inputs,
  ...
}:
{
  home.packages = [
    inputs.zen-browser.packages.${pkgs.system}.default
  ];

  xdg.mimeApps.defaultApplications = {
    "text/html" = [ "zen.desktop" ];
    "text/xml" = [ "zen.desktop" ];
    "x-scheme-handler/http" = [ "zen.desktop" ];
    "x-scheme-handler/https" = [ "zen.desktop" ];
  };
}
