{
  lib,
  pkgs,
  ...
}:
let
  calamaresAutostart = pkgs.makeAutostartItem {
    name = "io.calamares.calamares";
    package = pkgs.calamares-nixos;
  };
in
{
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  environment.systemPackages = with pkgs; [
    kdePackages.kpmcore
    calamares-nixos
    calamaresAutostart
    calamares-nixos-extensions
    glibcLocales
  ];

  i18n.supportedLocales = [ "all" ];

  # installation-cd defines initial passwords; dot.nix owns the final hashes.
  users.users.nixos.initialHashedPassword = lib.mkForce null;
  users.users.root.initialHashedPassword = lib.mkForce null;
}
