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
      "toph@caenus" = let
          hostName = "caenus";
          pkgs = armPkgs;
          home = ./. + "/host/${hostName}/home"; 
      in home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit hostName; };  
        modules = [ home ];
      };

      "toph@cloud" = let
          hostName = "cloud";
          pkgs = x86Pkgs;
          home = ./. + "/host/${hostName}/home"; 
      in home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit hostName; };  
        modules = [ home ];
      };

      "toph@dockge" = let
          hostName = "dockge";
          pkgs = x86Pkgs;
          home = ./. + "/host/${hostName}/home"; 
      in home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit hostName; };  
        modules = [ home ];
      };

      "toph@nix" = let
          hostName = "nix";
          pkgs = x86Pkgs;
          home = ./. + "/host/${hostName}/home"; 
      in home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit hostName; };  
        modules = [ home ];
      };
      
      "toph@proxy" = let
          hostName = "proxy";
          pkgs = x86Pkgs;
          home = ./. + "/host/${hostName}/home"; 
      in home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit hostName; };  
        modules = [ home ];
      };
    };
  };
}
