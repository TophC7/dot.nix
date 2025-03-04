# Development utilities I want across all systems
{
  lib,
  pkgs,
  ...
}:
{
  imports = lib.custom.scanPaths ./.;

  home.packages = lib.flatten [
    (builtins.attrValues {
      inherit (pkgs)
        # Development
        direnv
        delta # diffing
        gh # github cli

        logisim-evolution
        mcaselector
        prettierd

        # nix
        nixpkgs-review
        nixfmt-rfc-style

        # networking
        nmap

        # Diffing
        difftastic

        # serial debugging
        screen

        # Standard man pages for linux API
        man-pages
        man-pages-posix
        ;
      inherit (pkgs.jetbrains)
        idea-ultimate
        jetbrains-toolbox
        ;
    })
  ];
}
