###############################################################
#
#  Zebes - Main Server
#  NixOS running on Ryzen 5 5600G, RX 7900 GRE, 32GB RAM
#
#  Docker environment, Komodo, Authentik, Game Servers, etc.
#  Ai environment, Ollama, Oterm, Open WebUI, etc.
#
###############################################################

{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  username = "toph";
  user = config.secretsSpec.users.${username};
  firewall = config.secretsSpec.firewall.zebes;
in
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
      "hosts/global/common/docker.nix"
      "hosts/global/common/nvtop.nix"
    ])
  ];

  ## Host Specifications ##
  hostSpec = {
    hostName = "zebes";
    username = username;
    hashedPassword = user.hashedPassword;
    email = user.email;
    handle = user.handle;
    userFullName = user.fullName;
    isServer = true;
    isMinimal = true;
  };

  networking = {
    enableIPv6 = false;
    firewall = {
      allowedTCPPorts = firewall.allowedTCPPorts;
      allowedTCPPortRanges = firewall.allowedTCPPortRanges;
      allowedUDPPorts = firewall.allowedUDPPorts;
    };
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [
    lazydocker
    compose2nix
  ];

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
