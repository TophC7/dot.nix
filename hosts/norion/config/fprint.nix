{ ... }:
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

  # Configure PAM authentication for fingerprint support
  security.pam.services = {
    # Enable fingerprint authentication for sudo
    sudo.fprintAuth = true;

    # Enable fingerprint authentication for system login (TTY)
    # Set to false if you want to ensure password fallback is always available
    login.fprintAuth = false;

    # Enable fingerprint authentication for polkit (system authentication dialogs)
    polkit-1.fprintAuth = true;
  };
}
