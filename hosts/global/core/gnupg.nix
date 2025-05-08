{ pkgs, ... }:
{
  # GnuPG
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };
  services.pcscd.enable = true;
}
