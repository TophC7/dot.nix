{
  config,
  inputs,
  secrets,
  lib,
  host,
  ...
}:
let
  sworm = secrets.service.sworm;
  address = sworm.address or "10.2.2.2:7420";
  # tmpfiles reads the argument as one line with C escapes.
  clientKey = lib.replaceStrings [ "\\" "\n" ] [ "\\\\" "\\n" ] sworm.clients.${host.hostName}.key;
in
{
  imports = [
    inputs.sworm.homeManagerModules.default
  ];

  programs.sworm = {
    enable = true;
    settings = {
      window = {
        external_file_open_mode = "prefer_folder";
        external_folder_open_mode = "new_window";
        tab_beam_position = "bottom";
        theme = "system";
      };
      remotes = {
        nimbus = {
          inherit address;
          inherit (sworm.server) fingerprint;
        };
      };
    };
  };

  # Written, not linked: sworm, like ssh, refuses keys other users can read.
  # `f+` rewrites content and mode on every activation and login.
  systemd.user.tmpfiles.rules = [
    "f+ ${config.xdg.configHome}/sworm/client.pem 0600 - - - ${clientKey}"
  ];
}
