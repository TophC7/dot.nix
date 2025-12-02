{
  pkgs,
  config,
  lib,
  ...
}:

let
  ## SSH Keys ##
  key = {
    pub = ""; # Set a key for easy SSH access
  };

  sshConfig = pkgs.writeText "ssh-config" ''
    Host git.ryot.foo
      IdentityFile "~/.ssh/git"

    Host *
      ForwardAgent no
      AddKeysToAgent yes
      Compression no
      ServerAliveInterval 5
      ServerAliveCountMax 3
      HashKnownHosts no
      UserKnownHostsFile ~/.ssh/known_hosts
      ControlMaster no
      ControlPath ~/.ssh/master-%r@%n:%p
      ControlPersist no

      UpdateHostKeys ask
  '';
in
{
  secretsSpec = {
    users = {
      nixos = {
        hashedPassword = "$6$rounds=656000$5ehID8CrGOgiG4Ms$MiS68cPnrREv1URzlCcyFnJntVhWMKAnY7ZNaEvgEG36vV1KBnQHyv6HkPmOeh8aGOljYOR0aWFg.irg6ahT3."; # nixos
        email = "admin@localhost";
        handle = "nixos";
        fullName = "NixOS Live User";

        ssh = {
          publicKeys = [
            key.pub
          ];
          config = sshConfig;
        };
      };
    };
  };

  # Override the installation-cd defaults to prevent password conflicts
  users.users.nixos.initialHashedPassword = lib.mkForce null;
  users.users.root.initialHashedPassword = lib.mkForce null;
}
