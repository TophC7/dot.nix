{
  host,
  pkgs,
  ...
}:
{
  # Colord daemon for color management and device detection
  services.colord.enable = true;

  # Grant host user access to colord device group
  users.users.${host.user.name}.extraGroups = [ "colord" ];

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      argyllcms
      displaycal
      ;
  };
}
