{ lib, ... }:
{
  programs.ssh.startAgent = true;

  services = {
    openssh = {
      enable = true;
      ports = [ 22 ];

      settings = {
        AllowUsers = null; # everyone
        PasswordAuthentication = lib.mkDefault false;
        PermitRootLogin = lib.mkDefault "no";
        KbdInteractiveAuthentication = false;
        # Automatically remove stale sockets
        StreamLocalBindUnlink = "yes";
        # Allow forwarding ports to everywhere
        GatewayPorts = "clientspecified";
      };
    };
    gnome.gcr-ssh-agent.enable = false;
  };

  networking.firewall.allowedTCPPorts = [ 22 ];
}
