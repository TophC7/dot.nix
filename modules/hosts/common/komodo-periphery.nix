# Komodo Periphery — lightweight agent that lets the central Komodo Core
# (on zebes) manage Docker stacks, repos, and builds on this host via RPC.
{
  host,
  hosts,
  lib,
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
    ssl.enable = lib.mkDefault false;
    user = lib.mkDefault user;
    group = lib.mkDefault "ryot";
    passkeys = [ passkey ];
    rootDirectory = lib.mkDefault "/ryot/komodo";
    allowedIps = [
      hosts.zebes.ip
    ];
  };

  # Relax systemd sandbox so periphery can spawn terminals and access user shells
  systemd.services.komodo-periphery.serviceConfig = {
    ProtectHome = lib.mkForce false;
    NoNewPrivileges = lib.mkForce false;
  };

  networking.firewall.allowedTCPPorts = [ 8120 ];
}
