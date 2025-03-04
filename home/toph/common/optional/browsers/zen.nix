{
  config,
  pkgs,
  inputs,
  ...
}:
{
  home.packages = builtins.attrValues {
    inherit (inputs.zen-browser.packages."${pkgs.system}")
      twilight
      ;
  };

  xdg.mimeApps.defaultApplications = {
    "text/html" = [ "zen.desktop" ];
    "text/xml" = [ "zen.desktop" ];
    "x-scheme-handler/http" = [ "zen.desktop" ];
    "x-scheme-handler/https" = [ "zen.desktop" ];
  };
}
