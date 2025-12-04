###############################################################
#
#  Nexus - Router & Services Host
#
#  Router, Firewall, DHCP, DNS, Docker services
#  Pangolin Proxy, Zero Trust access, Wireguard VPN, Rathole tunnels
#
###############################################################

{
  flakeRoot,
  lib,
  ...
}:
{
  imports = lib.flatten [
    ## Nexus Specific Imports ##
    (lib.fs.scanPaths ./.)

    ## Additional Configs ##
    (map (lib.fs.relativeTo flakeRoot) [
      "modules/hosts/common/acme.nix"
      "modules/hosts/common/docker.nix"
      "modules/hosts/common/pangolin/newt.nix"
    ])
  ];

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
