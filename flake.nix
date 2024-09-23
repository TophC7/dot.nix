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
        "toph@caenus" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          hostName = "caenus";
          modules = [ ./home-manager ];
          specialArgs = { inherit hostName; };
        };

        "toph@cloud" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          hostName = "cloud";
          modules = [ ./home-manager ];
          specialArgs = { inherit hostName; };
        };

        "toph@dockge" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          hostName = "dockge";
          modules = [ ./home-manager ];
          specialArgs = { inherit hostName; };
        };

        "toph@nix" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          hostName = "nix";
          modules = [ ./home-manager ];
          specialArgs = { inherit hostName; };
        };
        
        "toph@proxy" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          hostName = "proxy";
          modules = [ ./home-manager ];
          specialArgs = { inherit hostName; };
        };
      };
    };
}
