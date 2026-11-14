{
  config,
  inputs,
  secrets,
  lib,
  host,
  ...
}:
let
  axome = secrets.service.sworm;
  address = axome.address or "10.2.2.2:7420";
  # tmpfiles reads the argument as one line with C escapes.
  clientKey = lib.replaceStrings [ "\\" "\n" ] [ "\\\\" "\\n" ] axome.clients.${host.hostName}.key;
in
{
  imports = [
    inputs.axome.homeManagerModules.default
  ];

  programs.axome = {
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
          inherit (axome.server) fingerprint;
        };
      };
    };
  };

  # Written, not linked: axome, like ssh, refuses keys other users can read.
  # `f+` rewrites content and mode on every activation and login.
  systemd.user.tmpfiles.rules = [
    "f+ ${config.xdg.configHome}/axome/client.pem 0600 - - - ${clientKey}"
  ];
}
