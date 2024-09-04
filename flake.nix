{
  description = "Unstable Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ (import ./nixos/overlays) ];
      };
    in {
      nixosConfigurations = {
        cloud = lib.nixosSystem {
          inherit system;
          modules = [ ./nixos/configuration.nix ];
        };
      };
      homeConfigurations = {
          toph = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [ ./home-manager/home.nix ];
          };
      };
    };
}
