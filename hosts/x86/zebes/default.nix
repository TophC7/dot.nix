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
  config,
  host,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    ## Zebes Only ##
    ./config

    ## Hardware ##
    ./hardware.nix
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    (map lib.custom.relativeToRoot [
      ## Required Configs ##
      "hosts/global/core"

      ## Optional Configs ##
      "hosts/global/common/acme"
      "hosts/global/common/bluetooth.nix"
      "hosts/global/common/ddcutil.nix" # ddcutil for monitor controls
      "hosts/global/common/docker.nix"
      "hosts/global/common/nvtop.nix" # GPU monitor (not available in home-manager)
      "hosts/global/common/pangolin/newt.nix"
      # "hosts/global/common/plymouth.nix" # fancy boot screen
      # "hosts/global/common/solaar.nix" # Logitech Unifying Receiver support
    ])
  ];

  networking = {
    enableIPv6 = false;
    firewall = host.network.firewall;
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
