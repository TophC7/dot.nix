{
  programs.ssh.startAgent = true;

  services.openssh = {
    enable = true;
    ports = [ 22 ];

    settings = {
      AllowUsers = null; # everyone
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
      # Automatically remove stale sockets
      StreamLocalBindUnlink = "yes";
      # Allow forwarding ports to everywhere
      GatewayPorts = "clientspecified";
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 ];
}
