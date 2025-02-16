# FIXME: this shit is a mess i need to learn how to do this properly
{
  description = "Unstable Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
    };
    # nixvirt = {
    #   url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # arion = {
    #   url = "github:hercules-ci/arion";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;

      admin = "toph";
      user = "toph";
      ARM = "aarch64-linux"; # ARM systems
      X86 = "x86_64-linux"; # x86_64 systems
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
              inherit admin hostName;
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
              inherit admin hostName;
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
              inherit admin hostName;
            };
            system = X86;
            modules = [
              ./nix
              default
              inputs.vscode-server.nixosModules.default
              (
                { config, pkgs, ... }:
                {
                  services.vscode-server.enable = true;
                  services.vscode-server.enableFHS = true;
                  programs.nix-ld = {
                    enable = true;
                    package = pkgs.nix-ld-rs;
                  };
                }
              )
            ];
          };

        nix =
          let
            hostName = "nix";
            default = ./. + "/host/${hostName}";
          in
          lib.nixosSystem {
            specialArgs = {
              inherit admin hostName;
            };
            system = X86;
            modules = [
              ./nix
              default
              inputs.vscode-server.nixosModules.default
              (
                { config, pkgs, ... }:
                {
                  services.vscode-server.enable = true;
                }
              )
            ];
          };

        proxy =
          let
            hostName = "proxy";
            default = ./. + "/host/${hostName}";
          in
          lib.nixosSystem {
            specialArgs = {
              inherit admin hostName;
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
              inherit admin hostName inputs;
            };
            system = X86;
            modules = [
              ./nix
              default
            ];
          };

        haze =
          let
            user = "cesar";
            hostName = "haze";
            default = ./. + "/host/${hostName}";
          in
          lib.nixosSystem {
            specialArgs = {
              inherit admin user hostName;
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
          "${admin}@caenus" =
            let
              hostName = "caenus";
              pkgs = armPkgs;
              home = ./. + "/host/${hostName}/home";
            in
            inputs.home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit admin user hostName;
              };
              modules = [ home ];
            };

          "${admin}@cloud" =
            let
              hostName = "cloud";
              pkgs = x86Pkgs;
              home = ./. + "/host/${hostName}/home";
            in
            inputs.home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit admin user hostName;
              };
              modules = [ home ];
            };

          "${admin}@komodo" =
            let
              hostName = "komodo";
              pkgs = x86Pkgs;
              home = ./. + "/host/${hostName}/home";
            in
            inputs.home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit admin user hostName;
              };
              modules = [ home ];
            };

          "${admin}@nix" =
            let
              hostName = "nix";
              pkgs = x86Pkgs;
              home = ./. + "/host/${hostName}/home";
            in
            inputs.home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit admin user hostName;
              };
              modules = [ home ];
            };

          "${admin}@proxy" =
            let
              hostName = "proxy";
              pkgs = x86Pkgs;
              home = ./. + "/host/${hostName}/home";
            in
            inputs.home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit admin user hostName;
              };
              modules = [ home ];
            };

          "${admin}@rune" =
            let
              hostName = "rune";
              pkgs = x86Pkgs;
              home = ./. + "/host/${hostName}/home";
              zen = inputs.zen-browser.packages."${X86}".beta;
            in
            inputs.home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit
                  admin
                  user
                  hostName
                  zen
                  inputs
                  ;
              };
              modules = [ home ];
            };

          "${admin}@haze" =
            let
              user = "cesar";
              hostName = "haze";
              pkgs = x86Pkgs;
              home = ./. + "/host/${hostName}/home";
              zen = inputs.zen-browser.packages."${X86}".beta;
            in
            inputs.home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit
                  admin
                  user
                  hostName
                  zen
                  ;
              };
              modules = [ home ];
            };

          "cesar@haze" =
            let
              hostName = "haze";
              pkgs = x86Pkgs;
              home = ./. + "/host/${hostName}/home";
              zen = inputs.zen-browser.packages."${X86}".beta;
            in
            inputs.home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit
                  admin
                  user
                  hostName
                  zen
                  ;
              };
              modules = [ home ];
            };
        };
    };
}
