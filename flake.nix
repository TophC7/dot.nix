{
  description = "Unstable Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nextcloud29 = {
      url = "github:nix-unstable/nextcloud";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nextcloud29, ... }:
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
      nixosConfigurations = {
        nix = lib.nixosSystem {
          inherit system;
          modules = [ ./nextcloud/nextcloud.nix ];
        };
      };
    };
}
