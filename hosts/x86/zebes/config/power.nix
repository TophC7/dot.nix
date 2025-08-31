{ ... }:
{
  # Disable suspend/sleep/hibernate for server with GUI
  services.logind = {
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
    lidSwitchExternalPower = "ignore";
    powerKey = "ignore";
    suspendKey = "ignore";
    hibernateKey = "ignore";
    settings = {
      Login = {
        IdleAction = "ignore";
        IdleActionSec = "0";
      };
    };
  };

  # Disable power management features
  powerManagement = {
    enable = false;
    powertop.enable = false;
  };

  # Prevent system sleep
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # Keep the system always on (GDM with Wayland)
  services.displayManager.gdm.autoSuspend = false;
}
