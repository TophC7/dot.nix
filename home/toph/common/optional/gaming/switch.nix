# This module just provides a customized .desktop file with gamescope args dynamically created based on the
# host's monitors configuration
{
  pkgs,
  config,
  lib,
  ...
}:

let

  path = lib.custom.relativeToRoot "pkgs/common/citron-emu/package.nix";
  citron-emu = pkgs.callPackage path { inherit pkgs; };

  backup-wrapper = import ./scripts/backup.nix { inherit pkgs; };

  user = config.hostSpec.username;

in
{
  home.packages = with pkgs; [
    citron-emu
    ryubing
  ];

  xdg.desktopEntries = {
    Ryujinx = {
      name = "Ryubing w/ Backups";
      comment = "Ryubing Emulator with Save Backups";
      exec = ''fish ${backup-wrapper} /home/${user}/.config/Ryujinx/bis/user/save /pool/Backups/Switch/RyubingSaves 960 20 -- ryujinx''; # Should amount to be ~8 hours of playtime in 30 backups
      icon = "Ryujinx";
      type = "Application";
      terminal = false;
      categories = [
        "Game"
        "Emulator"
      ];
      mimeType = [
        "application/x-nx-nca"
        "application/x-nx-nro"
        "application/x-nx-nso"
        "application/x-nx-nsp"
        "application/x-nx-xci"
      ];
      prefersNonDefaultGPU = true;
      settings = {
        StartupWMClass = "Ryujinx";
        GenericName = "Nintendo Switch Emulator";
      };
    };

    citron-emu = {
      name = "Citron w/ Backups";
      comment = "Citron Emulator with Save Backups";
      exec = ''fish ${backup-wrapper} /home/${user}/.local/share/citron/nand/user/save /pool/Backups/Switch/CitronSaves 960 20 -- citron-emu''; # Should amount to be ~8 hours of playtime in 30 backups
      icon = "applications-games";
      type = "Application";
      terminal = false;
      categories = [
        "Game"
        "Emulator"
      ];
      mimeType = [
        "application/x-nx-nca"
        "application/x-nx-nro"
        "application/x-nx-nso"
        "application/x-nx-nsp"
        "application/x-nx-xci"
      ];
      prefersNonDefaultGPU = true;
      settings = {
        StartupWMClass = "Citron";
        GenericName = "Nintendo Switch Emulator";
      };
    };
  };
}
