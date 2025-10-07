###############################################################
#
#  Nexus - Router & Services Host
#
#  Router, Firewall, DHCP, DNS, Docker services
#  Pangolin Proxy, Zero Trust access, Wireguard VPN, Rathole tunnels
#
###############################################################

{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    ## Nexus Only ##
    ./config

    ## Hardware ##
    ./hardware.nix

    (map lib.custom.relativeToRoot [
      ## Required Configs ##
      "hosts/global/core"

      ## Optional Configs ##
      "hosts/global/common/acme"
      "hosts/global/common/docker.nix"
      "hosts/global/common/pangolin/newt.nix"
    ])
  ];

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
