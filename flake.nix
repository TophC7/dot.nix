{
  description = "Unstable Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations = {
        nix = lib.nixosSystem {
          inherit system;
          modules = [ ./nixos/configuration.nix ];
        };
      };
    };
}
