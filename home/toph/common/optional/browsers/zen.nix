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
    "text/html" = [ "zen_twilight.desktop" ];
    "text/xml" = [ "zen_twilight.desktop" ];
    "x-scheme-handler/http" = [ "zen_twilight.desktop" ];
    "x-scheme-handler/https" = [ "zen_twilight.desktop" ];
  };
}
