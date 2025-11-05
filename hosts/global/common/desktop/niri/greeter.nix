# Niri greeter using DankMaterialShell
{
  config,
  host,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # Import the DankMaterialShell greeter module
  imports = [ inputs.dankMaterialShell.nixosModules.greeter ];

  # Enable and configure the DankMaterialShell greeter for Niri
  programs.dankMaterialShell.greeter = {
    enable = true;

    # Use Niri as the compositor
    compositor = {
      name = "niri";
      customConfig = "";
    };

    # Logging configuration
    logs = {
      save = false;
      path = "/var/log/dms-greeter.log";
    };
  };

  # Configure greetd for auto-login if enabled
  services.greetd.settings = lib.mkIf host.autoLogin {
    initial_session = {
      command = "${pkgs.niri}/bin/niri-session";
      user = host.user.name;
    };
  };
}
