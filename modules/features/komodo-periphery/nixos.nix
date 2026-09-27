# Komodo Periphery — lightweight agent that lets the central Komodo Core
# (on zebes) manage Docker stacks, repos, and builds on this host via RPC.
{
  config,
  host,
  hosts,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  passkey = secrets.service.komodo.PASSKEY;
  user = host.user.name;
in
{
  services.komodo-periphery = {
    enable = true;
    user = lib.mkDefault user;
    group = lib.mkDefault "ryot";
    rootDirectory = lib.mkDefault "/ryot/komodo";

    # Compatibility bridge while Core moves to v2 PKI authentication.
    passkeyFiles = pkgs.writeText "komodo-passkeys" passkey;

    inbound = {
      ssl.enable = lib.mkDefault false;
      allowedIps = [
        hosts.zebes.ip
      ];
    };
  };

  systemd.services.komodo-periphery = {
    # Periphery shells out to Docker and OpenSSL for stack operations and certificates.
    path = [
      config.virtualisation.docker.package
      pkgs.openssl
    ];

    # Relax sandbox so periphery can spawn terminals and access user shells.
    serviceConfig = {
      ProtectHome = lib.mkForce false;
      NoNewPrivileges = lib.mkForce false;
    };
  };

  networking.firewall.allowedTCPPorts = [ 8120 ];
}
