{ 
    enable = true;
    fqdn = "mail.ryot.foo";
    domains = [ "ryot.foo" ];

    enableImapSsl = true;
    enableSubmissionSsl = true;

    # A list of all login accounts. To create the password hashes, use
    # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
    loginAccounts = {
        "[REDACTED]" = {
            hashedPassword = builtins.readFile ./admin.pass;
            aliases = ["[REDACTED]"];
        };
    };

    certificateScheme = "acme";
}