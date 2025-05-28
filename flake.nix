{
  description = "Toph's Nix-Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/5278f55d2c2c568db38ed03370606b5e009e34df"; # Bleeding edge packages from Chaotic-AUR

    ## NixOS ##

    hardware = {
      url = "github:nixos/nixos-hardware";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    ## VM tools ##

    # nixtheplanet.url = "github:matthewcroughan/nixtheplanet";
    nixvirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    ## Theming ##

    rose-pine-hyprcursor = {
      url = "github:ndom91/rose-pine-hyprcursor";
    };

    stylix.url = "github:danth/stylix";

    ## Misc Packages ##

    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    # nixcord.url = "github:kaylorben/nixcord";
    # spicetify-nix = {
    #   url = "github:Gerg-L/spicetify-nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    snapraid-aio = {
      # url = "git+https://git.ryot.foo/toph/snapraid-aio.nix.git";
      url = "git+https://git.ryot.foo/toph/snapraid-aio.nix.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    yay = {
      url = "git+https://git.ryot.foo/toph/yay.nix.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;

      ARM = "aarch64-linux";
      X86 = "x86_64-linux";

      forAllSystems = nixpkgs.lib.genAttrs [
        ARM
        X86
      ];

      ## Host Config ##

      mkHost = host: isARM: {
        ${host} =
          let
            func = if isARM then ARM else X86;
            systemFunc = func;
          in
          lib.nixosSystem {
            specialArgs = {
              inherit
                inputs
                outputs
                isARM
                ;
              system = systemFunc;
              # INFO: Extend lib with lib.custom; This approach allows lib.custom to propagate into hm
              lib = nixpkgs.lib.extend (self: super: { custom = import ./lib { inherit (nixpkgs) lib; }; });
            };
            modules = [
              {
                #INFO: Overlay application for custom packages
                nixpkgs.overlays = [
                  self.overlays.default
                ];
              }

              # Import secrets
              ./modules/global/secret-spec.nix
              ./secrets.nix

              # Host-specific configuration
              ./hosts/nixos/${host}
            ];
          };
      };
      # Invoke mkHost for each host config that is declared for either X86 or ARM
      mkHostConfigs =
        hosts: isARM: lib.foldl (acc: set: acc // set) { } (lib.map (host: mkHost host isARM) hosts);
      readHosts = folder: lib.attrNames (builtins.readDir ./hosts/${folder});
    in
    {
      overlays = import ./overlays { inherit inputs; };

      nixosConfigurations = mkHostConfigs (readHosts "nixos") false;

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };

          # Get all package directories from pkgs/
          packageDirs = builtins.attrNames (builtins.readDir ./pkgs);

          # Filter to only include names that resulted in valid packages
          validPackages = builtins.filter (name: builtins.hasAttr name pkgs) packageDirs;

          # Create a set with all the packages
          customPackages = builtins.listToAttrs (
            builtins.map (name: {
              inherit name;
              value = pkgs.${name};
            }) validPackages
          );
        in
        customPackages
      );
    };
}
