{
  pkgs,
  lib,
  config,
  ...
}:
{
  # Enable fingerprint scanner support
  services.fprintd = {
    enable = true;
    # Uncomment and set the TOD driver if the standard driver doesn't work
    # tod = {
    #   enable = true;
    #   driver = pkgs.libfprint-2-tod1-elan; # or pkgs.libfprint-2-tod1-goodix
    # };
  };

  # Ensure fprintd service starts properly
  systemd.services.fprintd = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "simple";
  };

  # Configure PAM authentication for fingerprint support
  security.pam.services = {
    # Enable fingerprint authentication for sudo
    sudo.fprintAuth = true;

    # Enable fingerprint authentication for system login (TTY)
    # Set to false if you want to ensure password fallback is always available
    login.fprintAuth = false;

    # Enable fingerprint authentication for GDM (Wayland)
    # This allows fingerprint login at the GNOME login screen
    gdm.fprintAuth = lib.mkIf config.services.displayManager.gdm.enable true;

    # Enable fingerprint authentication for GDM's fingerprint service
    # This is needed for proper GNOME integration on Wayland
    gdm-fingerprint = lib.mkIf config.services.displayManager.gdm.enable {
      text = ''
        auth       required                    pam_shells.so
        auth       requisite                   pam_nologin.so
        auth       requisite                   pam_faillock.so      preauth
        auth       required                    ${pkgs.fprintd}/lib/security/pam_fprintd.so
        auth       optional                    pam_permit.so
        auth       required                    pam_env.so
        auth       [success=ok default=1]      ${pkgs.gdm}/lib/security/pam_gdm.so
        auth       optional                    ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so

        account    include                     login

        password   required                    pam_deny.so

        session    include                     login
        session    optional                    ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so auto_start
      '';
    };

    # Enable fingerprint authentication for polkit (system authentication dialogs)
    polkit-1.fprintAuth = true;
  };
}
