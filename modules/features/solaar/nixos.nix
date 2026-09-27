{ pkgs, ... }:
{
  programs.solaar = {
    enable = true;
    package = pkgs.solaar;
    userService = {
      enable = true;
      window = "hide";
      batteryIcons = "symbolic";
    };
  };

  environment.systemPackages = with pkgs; [
    gnomeExtensions.solaar-extension
  ];
}
