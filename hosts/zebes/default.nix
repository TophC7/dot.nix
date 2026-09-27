###############################################################
#
#  Zebes - Main Server
#  NixOS running on Ryzen 5 5600G, RX 7900 GRE, 32GB RAM
#
#  Docker environment, Komodo, Game Servers, etc.
#  Ai environment, Ollama, Oterm, Open WebUI, etc.
#
###############################################################

{
  host,
  inputs,
  lib,
  ...
}:
{
  imports = lib.flatten [
    ## Zebes Specific Imports ##
    ./hardware.nix
    ./config

    ## Hardware ##
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    ## Additional Configs ##
    (lib.features [
      "acme"
      "bluetooth"
      "ddcutil"
      "docker"
      "nvtop"
      "komodo-periphery"
      "pangolin/newt"
    ])
  ];

  networking = {
    enableIPv6 = false;
    firewall = {
      allowedTCPPorts = [
        111 # rpcbind
        222 # Forgejo SSH
        2049 # NFSv4
        10048 # mountd
      ];
      allowedTCPPortRanges = [
        {
          from = 25565;
          to = 25570;
        } # Game servers
      ];
      allowedUDPPorts = [
        111 # rpcbind
        2049 # NFSv4
        5520 # Hytale
        10048 # mountd
        15637 # Enshrouded
        7777 # Astroneer
      ];
    };
    networkmanager.settings.connection = {
      # Don't randomize MAC address
      "wifi.mac-address-randomization" = 1;
      "ethernet.cloned-mac-address" = "preserve";
    };
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
