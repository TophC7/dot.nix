{ pkgs, ... }:

{
  environment.etc."snapraid.conf".text = builtins.readFile ./snapraid.conf;
  environment.etc."snapraid-runner.conf".text = ''
    [snapraid]
    executable = ${pkgs.snapraid}/bin/snapraid
    config = /etc/snapraid.conf
    deletethreshold = 40
    touch = false

    [logging]
    file = /var/log/snapraid-runner.log
    maxsize = 5000

    [email]
    sendon = 
    short = true
    subject = [SnapRAID] Status Report:
    from = cloud@ryot.foo
    to = [REDACTED]
    maxsize = 500

    [smtp]
    host = ryot.foo
    port =
    ssl = true
    tls = true
    user = admin
    password = [REDACTED]

    [scrub]
    enabled = true
    plan = 12
    older-than = 10
  '';
}
