{
  pkgs,
  config,
  lib,
  hostSpec,
  secretsSpec,
  ...
}:
let
  # Generate local key paths for the config
  sshKeysMap = lib.mapAttrs (name: _: "${hostSpec.home}/.ssh/${name}") secretsSpec.ssh.privateKeys;

  # Create the SSH config file with local paths
  sshConfig = pkgs.writeText "ssh-config" ''
    Host git.ryot.foo
      IdentityFile ${sshKeysMap.git}

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

      IdentityFile ${sshKeysMap.pve}
      UpdateHostKeys ask
  '';
in
{
  home.file =
    {
      # SSH config file
      ".ssh/config_source" = {
        source = sshConfig;
        onChange = ''
          cp $HOME/.ssh/config_source $HOME/.ssh/config
          chmod 400 $HOME/.ssh/config
        '';
      };

      ".ssh/known_hosts_source" = {
        source = pkgs.writeText "known-hosts" (lib.concatStringsSep "\n" secretsSpec.ssh.knownHosts);
        onChange = ''
          cp $HOME/.ssh/known_hosts_source $HOME/.ssh/known_hosts
          chmod 644 $HOME/.ssh/known_hosts
        '';
      };
    }
    # Dynamically add all SSH private keys using the existing store paths
    # Ensures the keys have correct permissions and are not symlinks
    // lib.mapAttrs' (name: path: {
      name = ".ssh/${name}_source";
      value = {
        source = path;
        onChange = ''
          cp $HOME/.ssh/${name}_source $HOME/.ssh/${name}
          chmod 600 $HOME/.ssh/${name}
        '';
      };
    }) secretsSpec.ssh.privateKeys;
}
