{ modulesPath, config, pkgs, hostName, ... }:

let

    admin = "toph";
    password = "[REDACTED]";
    timeZone = "America/New_York";
    defaultLocale = "en_US.UTF-8";

in {
    ## TIMEZONE & LOCALE ##
    time.timeZone = timeZone;
    i18n.defaultLocale = defaultLocale;

    ## USERS ##
    users.mutableUsers = false;
    users.users."${admin}" = {
        isNormalUser = true;
        createHome = true;
        homeMode = "750";
        home = "/home/${admin}";
        password = password;
        extraGroups = [ "wheel" ];
        shell = pkgs.fish;
        openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClZstYoT64zHnGfE7LMYNiQPN5/gmCt382lC+Ji8lrH PVE"
        ];
    };

    # INFO: Enable passwordless sudo.
    security.sudo.extraRules  = [{
        users = [ admin ];
        commands = [{
            command = "ALL" ;
            options = [ "NOPASSWD" ];
        }];
    }];

    ## PROGRAMS & SERVICES ##
    # Shells
    environment.shells = with pkgs; [ bash fish ];
    programs.fish.enable = true;

    ## NETWORKING ##
    networking = {
        dhcpcd.enable = false;
        hostName = hostName;
        networkmanager.enable = true;
        useDHCP = true;
        useHostResolvConf = false;
        usePredictableInterfaceNames = true;
    };

    ## NIXOS ##
    systemd.tmpfiles.rules = [
        "d /home/toph/git 0750 toph users -" 
    ];
    # forces interfaces to be named predictably 
    # This value determines the NixOS release with which your system is to be
    system.stateVersion = "24.11";
    # Enable Flakes
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
}