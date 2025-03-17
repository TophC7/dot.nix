{ pkgs, lib, ... }:
let
  path = lib.custom.relativeToRoot "pkgs/common/monocraft-nerd-fonts/package.nix";
  monocraft-nerd-fonts = pkgs.callPackage path { inherit pkgs; };
in
{
  fonts = {
    packages = with pkgs; [
      # icon fonts
      material-symbols

      # Sans(Serif) fonts
      lexend
      noto-fonts
      noto-fonts-emoji
      roboto
      (google-fonts.override {
        fonts = [
          "Inter"
          "Laila"
        ];
      })

      # monospace fonts
      monocraft
      monocraft-nerd-fonts

      # nerdfonts
      nerd-fonts.fira-code
      nerd-fonts.symbols-only
    ];

    # causes more issues than it solves
    enableDefaultPackages = false;

    # user defined fonts
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "Laila" ];
        sansSerif = [ "Lexend" ];
        monospace = [ "Monocraft" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
