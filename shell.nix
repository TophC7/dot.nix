# This is a Nix flake shell that provides a minimal environment for new install or system recovery
{
  pkgs ?
    # If pkgs is not defined, instantiate nixpkgs from locked commit
    let
      lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
      nixpkgs = fetchTarball {
        url = "https://github.com/nixos/nixpkgs/archive/${lock.rev}.tar.gz";
        sha256 = lock.narHash;
      };
      # Import overlays from the flake's overlay structure
      overlays = [
        (import ./overlays { inputs = { }; }).default
      ];
    in
    import nixpkgs { inherit overlays; },
  inputs ? null,
  ...
}:
let
  # Import yay directly from its flake, incase overlay or config flake fucks up
  yay = builtins.getFlake "git+https://git.ryot.foo/toph/yay.nix.git";
  inherit (pkgs) lib;
in
{
  default = pkgs.mkShell {
    nativeBuildInputs =
      builtins.attrValues {
        inherit (pkgs)
          # Basic nix tools
          nix
          nixos-rebuild
          home-manager
          nh

          # Git and git-crypt
          git
          git-crypt
          gnupg
          gpg-tui

          # Shells
          fish
          bash

          # Config tools
          dconf2nix

          # Network tools
          curl
          wget

          # System tools
          coreutils
          findutils
          gzip
          zstd

          # Text editors
          micro
          nano

          # Diagnostics
          inxi
          pciutils
          usbutils
          lshw
          ;
      }
      ++ [
        yay.packages.${pkgs.system}.default
      ];

    # Overwrite FLAKE to current path, for yay and nh
    FLAKE = toString ./.;

    shellHook = ''
      clear
      echo "Minimal shell initialized with flake overlays"
      echo -e "Run '\033[1;34myay rebuild\033[0m' to rebuild your system if needed"
      echo -e "FLAKE environment variable is set to: \033[1;34m$FLAKE\033[0m"
    '';
  };
}
