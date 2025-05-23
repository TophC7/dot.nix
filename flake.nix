{
  description = "Toph's Nix-Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Pin stable vs unstable: use nixpkgs-stable for critical packages while nixpkgs follows the beta branch.
    # See overlays "stable-packages" and "unstable-packages" in ./overlays/default.nix.
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

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

      ARM = "aarch64-linux"; # ARM systems
      X86 = "x86_64-linux"; # x86_64 systems

      #
      # ========= Architectures =========
      #
      forAllSystems = nixpkgs.lib.genAttrs [
        ARM
        X86
      ];

      #
      # ========= Host Config Functions =========
      #
      # Handle a given host config based on whether its underlying system is nixos or darwin
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
              # ========== Extend lib with lib.custom ==========
              # NOTE: This approach allows lib.custom to propagate into hm
              # see: https://github.com/nix-community/home-manager/pull/3454
              lib = nixpkgs.lib.extend (self: super: { custom = import ./lib { inherit (nixpkgs) lib; }; });
            };
            modules = [
              # Apply the overlays to make custom packages available
              {
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
      # Return the hosts declared in the given directory
      readHosts = folder: lib.attrNames (builtins.readDir ./hosts/${folder});
    in
    {
      #
      # ========= Overlays =========
      #
      # Custom modifications/overrides to upstream packages.
      overlays = import ./overlays { inherit inputs; };

      #
      # ========= Host Configurations =========
      #
      # Building configurations is available through `just rebuild` or `nixos-rebuild --flake .#hostname`
      nixosConfigurations = mkHostConfigs (readHosts "nixos") false;

      # ========= Packages =========
      #
      # Add custom packages to be shared or upstreamed.
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
