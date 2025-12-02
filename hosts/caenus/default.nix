###############################################################
#
#  Caenus - Oracle VPS
#  NixOS VPS,  4vCPU, 24Ggb RAM, 200GB
#
#  Public IP
#
###############################################################

{
  flakeRoot,
  host,
  lib,
  ...
}:
{
  imports = lib.flatten [
    ## Caenus Specific Imports ##
    (lib.fs.scanPaths ./.)

    ## Additional Configs ##
    (map (lib.fs.relativeTo flakeRoot) [
      "modules/hosts/common/docker.nix"
    ])
  ];

  networking = {
    enableIPv6 = false;
    firewall = {
      allowedTCPPorts = [
        22 # SSH
        80 # HTTP (Pangolin/Traefik)
        222 # Forgejo SSH
        443 # HTTPS (Pangolin/Traefik)
        2333 # Rathole
        25565 # Minecraft
      ];
      allowedUDPPorts = [
        21820 # Client tunnels
        51820 # WireGuard OLM
        51821 # WireGuard VPN
      ];
    };
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
