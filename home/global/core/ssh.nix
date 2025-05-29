{
  pkgs,
  config,
  lib,
  hostSpec,
  secretsSpec,
  ...
}:
let
  ## Get the current user's SSH config ##
  userSsh = secretsSpec.users.${hostSpec.user}.ssh;

  ## Generate local key paths for the config ##
  sshKeysMap = lib.mapAttrs (name: _: "${hostSpec.home}/.ssh/${name}") userSsh.privateKeys;
in
{
  home.file =
    {
      ## SSH config file ##
      ".ssh/config_source" = {
        source = userSsh.config;
        onChange = ''
          cp $HOME/.ssh/config_source $HOME/.ssh/config
          chmod 400 $HOME/.ssh/config
        '';
      };

      ## Known hosts ##
      ".ssh/known_hosts_source" = {
        source = pkgs.writeText "known-hosts" (lib.concatStringsSep "\n" userSsh.knownHosts);
        onChange = ''
          cp $HOME/.ssh/known_hosts_source $HOME/.ssh/known_hosts
          chmod 644 $HOME/.ssh/known_hosts
        '';
      };
    }

    ## Dynamically copy all SSH private keys from store ensuring symlinks  are not used ##
    // lib.mapAttrs' (name: path: {
      name = ".ssh/${name}_source";
      value = {
        source = path;
        onChange = ''
          cp $HOME/.ssh/${name}_source $HOME/.ssh/${name}
          chmod 600 $HOME/.ssh/${name}
        '';
      };
    }) userSsh.privateKeys;
}
