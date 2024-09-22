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
        # overlays = [ (import ./nixos/overlays) ];
      };
    in {
      nixosConfigurations = {
        caenus = lib.nixosSystem {
          inherit system;
          modules = [ 
            ./nix
            ./host/caenus
          ];
        };
        
        cloud = lib.nixosSystem {
          inherit system;
          modules = [ 
            ./nix
            ./host/cloud
          ];
        };
        
        dockge = lib.nixosSystem {
          inherit system;
          modules = [ 
            ./nix
            ./host/dockge
          ];
        };
        
        nix = lib.nixosSystem {
          inherit system;
          modules = [ 
            ./nix
            ./host/nix
          ];
        };
        
        proxy = lib.nixosSystem {
          inherit system;
          modules = [ 
            ./nix
            ./host/proxy
          ];
        };
      };
      homeConfigurations = {
        toph = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home-manager ];
        };
      };
    };
}
