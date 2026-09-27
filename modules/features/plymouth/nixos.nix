{ lib, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.adi1090x-plymouth-themes ];
  boot = {
    kernelParams = [
      "quiet" # shut up kernel output prior to prompts
    ];
    plymouth = {
      enable = true;
      theme = lib.mkForce "motion";
      themePackages = [
        (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "motion" ]; })
      ];
    };
    consoleLogLevel = 0;
  };
}
