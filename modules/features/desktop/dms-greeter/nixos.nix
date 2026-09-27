# DMS greeter for Niri desktop hosts.
{
  host,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  niriSession = "${inputs.niri.packages.${system}.niri-unstable}/bin/niri-session";
in
{
  imports = [ inputs.dank-greeter.nixosModules.default ];

  programs.dms-greeter = {
    enable = lib.mkDefault true;
    compositor.name = lib.mkDefault "niri";
    configHome = lib.mkDefault "/home/${host.user.name}";
  };

  services.greetd.settings.initial_session = {
    command = lib.mkDefault niriSession;
    user = lib.mkDefault host.user.name;
  };
}
