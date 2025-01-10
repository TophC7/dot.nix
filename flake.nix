{
  description = "Unstable Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      zen-browser,
      ...
    }:
    let
      ARM = "aarch64-linux"; # ARM systems
      X86 = "x86_64-linux"; # x86_64 systems
      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations = {
        caenus =
          let
            hostName = "caenus";
            default = ./. + "/host/${hostName}";
          in
          lib.nixosSystem {
            specialArgs = {
              inherit hostName;
            };
            system = ARM;
            modules = [
              ./nix
              default
            ];
          };

        cloud =
          let
            hostName = "cloud";
            default = ./. + "/host/${hostName}";
          in
          lib.nixosSystem {
            specialArgs = {
              inherit hostName;
            };
            system = X86;
            modules = [
              ./nix
              default
            ];
          };

        komodo =
          let
            hostName = "komodo";
            default = ./. + "/host/${hostName}";
          in
          lib.nixosSystem {
            specialArgs = {
              inherit hostName;
            };
            system = X86;
            modules = [
              ./nix
              default
            ];
          };

        nix =
          let
            hostName = "nix";
            default = ./. + "/host/${hostName}";
          in
          lib.nixosSystem {
            specialArgs = {
              inherit hostName;
            };
            system = X86;
            modules = [
              ./nix
              default
            ];
          };

        proxy =
          let
            hostName = "proxy";
            default = ./. + "/host/${hostName}";
          in
          lib.nixosSystem {
            specialArgs = {
              inherit hostName;
            };
            system = X86;
            modules = [
              ./nix
              default
            ];
          };

        rune =
          let
            hostName = "rune";
            default = ./. + "/host/${hostName}";
          in
          lib.nixosSystem {
            specialArgs = {
              inherit hostName;
            };
            system = X86;
            modules = [
              ./nix
              default
            ];
          };
      };

      homeConfigurations =
        let
          armPkgs = import nixpkgs {
            system = ARM;
            config.allowUnfree = true;
          };
          x86Pkgs = import nixpkgs {
            system = X86;
            config.allowUnfree = true;
            # overlays = [ (import ./nixos/overlays) ];
          };
        in
        {
          "toph@caenus" =
            let
              hostName = "caenus";
              pkgs = armPkgs;
              home = ./. + "/host/${hostName}/home";
            in
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit hostName;
              };
              modules = [ home ];
            };

          "toph@cloud" =
            let
              hostName = "cloud";
              pkgs = x86Pkgs;
              home = ./. + "/host/${hostName}/home";
            in
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit hostName;
              };
              modules = [ home ];
            };

          "toph@komodo" =
            let
              hostName = "komodo";
              pkgs = x86Pkgs;
              home = ./. + "/host/${hostName}/home";
            in
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit hostName;
              };
              modules = [ home ];
            };

          "toph@nix" =
            let
              hostName = "nix";
              pkgs = x86Pkgs;
              home = ./. + "/host/${hostName}/home";
            in
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit hostName;
              };
              modules = [ home ];
            };

          "toph@proxy" =
            let
              hostName = "proxy";
              pkgs = x86Pkgs;
              home = ./. + "/host/${hostName}/home";
            in
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit hostName;
              };
              modules = [ home ];
            };

          "toph@rune" =
            let
              hostName = "rune";
              pkgs = x86Pkgs;
              home = ./. + "/host/${hostName}/home";
              zen = zen-browser.packages."${X86}".beta;
            in
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit hostName zen;
              };
              modules = [ home ];
            };
        };
    };
}
