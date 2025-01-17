{
  lib,
  ...
}:
{
  programs.ssh.startAgent = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClZstYoT64zHnGfE7LMYNiQPN5/gmCt382lC+Ji8lrH PVE"
  ];

  services.openssh = {
    enable = true;
    settings = {
      AllowUsers = null; # everyone
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = lib.mkDefault "no";
    };
  };
}
