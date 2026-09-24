{
  inputs,
  secrets,
  ...
}:
let
  swormSecret = secrets.service.sworm or { };
  fingerprint = swormSecret.fingerprint or "";
  address = swormSecret.address or "10.2.2.2:7420";
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
          inherit fingerprint;
        };
      };
    };
  };
}
