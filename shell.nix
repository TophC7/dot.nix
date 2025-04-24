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
  ...
}:
let
  # Explicitly add the yay package to the shell in case overlay fucks up
  yay = import ./pkgs/yay/package.nix { inherit pkgs lib; };
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

          # Git for repo management
          git
          git-crypt
          gnupg
          gpg-tui

          # Shells
          fish
          bash

          # Config tools
          dconf2nix

          # Network tools (for recovery scenarios)
          curl
          wget

          # System tools
          coreutils
          findutils
          gzip
          zstd

          # Text editors for emergency config edits
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
        yay
      ];

    FLAKE = toString ./.;

    shellHook = ''
      clear
      echo "Minimal shell initialized with flake overlays"
      echo -e "Run '\033[1;34myay rebuild\033[0m' to rebuild your system if needed"
      echo -e "FLAKE environment variable is set to: \033[1;34m$FLAKE\033[0m"
    '';
  };
}
