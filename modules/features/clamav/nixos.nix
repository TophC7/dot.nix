# ClamAV - Antivirus for compliance purposes
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.clamav = {
    daemon = {
      enable = true;
      settings = {
        # Log to syslog for audit trail
        LogSyslog = true;
        LogTime = true;
        MaxThreads = 2;
      };
    };

    # Keep virus definitions updated, once daily
    updater = {
      enable = true;
      interval = "daily";
      frequency = 1;
    };

    # Weekly scan
    scanner = {
      enable = true;
      interval = "weekly";
      scanDirectories = [
        "/home"
        "/tmp"
        "/var/tmp"
      ];
    };
  };

  # Make clamscan available for manual scans
  environment.systemPackages = [ pkgs.clamav ];
}
