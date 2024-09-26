{
  description = "Unstable Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: let
      ARM = "aarch64-linux"; # ARM systems
      X86 = "x86_64-linux"; # x86_64 systems
      lib = nixpkgs.lib;
    in {
    nixosConfigurations = {
      caenus = lib.nixosSystem {
        system = ARM;
        modules = [ 
          ./nix
          ./host/caenus
        ];
      };
    
      cloud = lib.nixosSystem {
        system = X86;
        modules = [ 
          ./nix
          ./host/cloud
        ];
      };
      
      dockge = lib.nixosSystem {
        system = X86;
        modules = [ 
          ./nix
          ./host/dockge
        ];
      };
      
      nix = lib.nixosSystem {
        system = X86;
        modules = [ 
          ./nix
          ./host/nix
        ];
      };
      
      proxy = lib.nixosSystem {
        system = X86;
        modules = [ 
          ./nix
          ./host/proxy
        ];
      };
    };

    homeConfigurations = let
        armPkgs = import nixpkgs {
          system = ARM;
          config.allowUnfree = true;
        };
        x86Pkgs = import nixpkgs {
          system = X86;
          config.allowUnfree = true;
          # overlays = [ (import ./nixos/overlays) ];
        };
      in {
      "toph@caenus" = home-manager.lib.homeManagerConfiguration {
        pkgs = armPkgs;
        modules = [ ./home ];
      };

      "toph@cloud" = home-manager.lib.homeManagerConfiguration {
        pkgs = x86Pkgs;
        modules = [ ./home ];
      };

      "toph@dockge" = home-manager.lib.homeManagerConfiguration {
        pkgs = x86Pkgs;
        modules = [ ./home ];
      };

      "toph@nix" = home-manager.lib.homeManagerConfiguration {
        pkgs = x86Pkgs;
        modules = [ ./home ];
      };
      
      "toph@proxy" = home-manager.lib.homeManagerConfiguration {
        pkgs = x86Pkgs;
        modules = [ ./home ];
      };
    };
  };
}
