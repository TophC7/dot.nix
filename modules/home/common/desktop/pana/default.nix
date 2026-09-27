{
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.pana.homeModules.default ] ++ lib.fs.scanPaths ./.;

  programs.pana = {
    enable = lib.mkDefault true;
    settings = {
      launcher.pinned = [
        "ghostty"
        "!caffeine"
        "!toggle overview"
      ];
      weather = {
        enabled = true;
        location = {
          latitude = 18.4725;
          longitude = -66.7157;
        };
      };
      screensaver = {
        oled = true;
        effect = "random";
        timeout-seconds = 80;
      };
    };
  };
}
