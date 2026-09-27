###############################################################
#
#  Nexus - Router & Services Host
#
#  Router, Firewall, DHCP, DNS, Docker services
#  Pangolin Proxy, Zero Trust access, Wireguard VPN, Rathole tunnels
#
###############################################################

{
  lib,
  ...
}:
{
  imports = lib.flatten [
    ## Nexus Specific Imports ##
    ./hardware.nix
    ./config

    ## Additional Configs ##
    (lib.features [
      "acme"
      "docker"
      "pangolin/newt"
      "komodo-periphery"
    ])
  ];

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
