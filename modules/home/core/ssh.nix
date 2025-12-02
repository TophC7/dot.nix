{
  pkgs,
  config,
  lib,
  host,
  secrets,
  ...
}:
let
  ## Get the current user's SSH config ##
  userSsh = secrets.users.${host.user.name}.ssh or { };

  ## SSH key creation function ##
  mkSshKeyFile =
    name: content:
    pkgs.writeTextFile {
      name = "ssh-key-${name}";
      text = content;
      executable = false;
      checkPhase = ''
        grep -q "BEGIN OPENSSH PRIVATE KEY" "$out" || (echo "Invalid SSH key format"; exit 1)
      '';
    };

  ## Create private key files from privateKeyContents ##
  privateKeys = lib.mapAttrs (name: content: mkSshKeyFile "${host.user.name}-${name}" content) (
    userSsh.privateKeyContents or { }
  );

  ## Generate local key paths for the config ##
  sshKeysMap = lib.mapAttrs (name: _: "~/.ssh/${name}") privateKeys;
in
{
  home.file =
    lib.optionalAttrs (userSsh ? config) {
      ## SSH config file ##
      ".ssh/config_source" = {
        text = userSsh.config;
        onChange = ''
          cp $HOME/.ssh/config_source $HOME/.ssh/config
          chmod 400 $HOME/.ssh/config
        '';
      };
    }
    // lib.optionalAttrs ((userSsh.knownHosts or [ ]) != [ ]) {
      ## Known hosts ##
      ".ssh/known_hosts_source" = {
        source = pkgs.writeText "known-hosts" (lib.concatStringsSep "\n" (userSsh.knownHosts or [ ]));
        onChange = ''
          cp $HOME/.ssh/known_hosts_source $HOME/.ssh/known_hosts
          chmod 644 $HOME/.ssh/known_hosts
        '';
      };
    }

    ## Dynamically copy all SSH private keys from store ensuring symlinks are not used ##
    // lib.mapAttrs' (name: path: {
      name = ".ssh/${name}_source";
      value = {
        source = path;
        onChange = ''
          cp $HOME/.ssh/${name}_source $HOME/.ssh/${name}
          chmod 600 $HOME/.ssh/${name}
        '';
      };
    }) privateKeys;
}
