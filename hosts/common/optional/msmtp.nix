{ inputs, config, ... }:

{
  programs.msmtp = {
    enable = true;
    setSendmail = true; # set the system sendmail to msmtp's

    accounts = {
      "default" = {
        host = "${config.hostSpec.email.msmtp-host}";
        port = 587;
        auth = true;
        tls = true;
        tls_starttls = true;
        from = "${config.hostSpec.email.notifier}";
        user = "${config.hostSpec.email.notifier}";
        passwordeval = "cat ${config.sops.secrets."passwords/msmtp".path}";
        logfile = "~/.msmtp.log";
      };
    };
  };
}
