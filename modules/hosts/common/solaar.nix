{ pkgs, inputs, ... }:
{
  imports = [
    inputs.solaar.nixosModules.default
  ];

  services.solaar = {
    enable = true; # Enable the service
    package = pkgs.solaar; # The package to use
    window = "hide"; # Show the window on startup (show, *hide*, only [window only])
    batteryIcons = "symbolic"; # Which battery icons to use (*regular*, symbolic, solaar)
    extraArgs = ""; # Extra arguments to pass to solaar on startup
  };

  environment.systemPackages = with pkgs; [
    gnomeExtensions.solaar-extension
  ];
}
