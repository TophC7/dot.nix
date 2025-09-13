###############################################################
#
#  Nexus - Router & Services Host
#
#  Router, Firewall, DHCP, DNS, Docker services
#  Cloudflare Tunnel Proxy, Zero Trust access
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
  firewall = config.secretsSpec.firewall.nexus;
in
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

  ## Host Specifications ##
  hostSpec = {
    hostName = "nexus";
    username = username;
    hashedPassword = user.hashedPassword;
    email = user.email;
    handle = user.handle;
    userFullName = user.fullName;
    isServer = true;
    isMinimal = true;
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  environment.etc = {
    "cloudflared/.keep" = {
      text = "This directory is used to store cloudflared configuration files.";
    };
  };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
