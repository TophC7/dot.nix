###############################################################
#
#  Meowl - Dell OptiPlex 3080
#
#  Intel Core i5-10505, UHD Graphics 630, 32GB RAM
#
###############################################################

{
  inputs,
  lib,
  ...
}:
{
  imports = lib.flatten [
    ./hardware.nix
    ./config
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
    (lib.features [
      "gaming"
      "docker"
      "pangolin/newt"
      "xdg"
      "zen"
    ])
  ];

  play.amd.enable = lib.mkForce false;

  networking.enableIPv6 = false;
  programs.nix-ld.enable = true;

  # Meowl is an always-on desktop and game-streaming host.
  systemd.sleep.settings.Sleep = {
    AllowSuspend = false;
    AllowHibernation = false;
    AllowSuspendThenHibernate = false;
    AllowHybridSleep = false;
  };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
