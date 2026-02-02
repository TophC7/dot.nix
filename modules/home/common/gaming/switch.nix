{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
let
  # wayscope = lib.getExe inputs.wayscope.packages.wayscope;
in
{
  home.packages = with pkgs; [
    nsz
    ryubing
    eden
  ];

  # # Desktop entry for Ryubing with wayscope
  # xdg.desktopEntries.ryubing = {
  #   name = "Ryubing";
  #   comment = "Nintendo Switch Emulator";
  #   exec = "${wayscope} run ${lib.getExe pkgs.ryubing}";
  #   icon = "Ryujinx";
  #   type = "Application";
  #   terminal = false;
  #   categories = [
  #     "Game"
  #     "Emulator"
  #   ];
  #   mimeType = [
  #     "application/x-nx-nca"
  #     "application/x-nx-nro"
  #     "application/x-nx-nso"
  #     "application/x-nx-nsp"
  #     "application/x-nx-xci"
  #   ];
  #   prefersNonDefaultGPU = true;
  #   settings = {
  #     StartupWMClass = "Ryubing";
  #     GenericName = "Nintendo Switch Emulator";
  #   };
  # };
}
