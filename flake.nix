{
  description = "Toph's Nix-Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable"; # Bleeding edge packages from Chaotic-AUR

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

    ## Gaming Packages ##

    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    play = {
      url = "github:tophc7/play.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    ## Misc Packages ##

    # nixcord.url = "github:kaylorben/nixcord";
    # spicetify-nix = {
    #   url = "github:Gerg-L/spicetify-nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    solaar = {
      url = "github:Svenum/Solaar-Flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snapraid-aio = {
      url = "github:tophc7/snapraid-aio.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    yay = {
      url = "github:tophc7/yay.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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

      # read host-dirs under e.g. hosts/x86 or hosts/arm
      readHosts = arch: lib.attrNames (builtins.readDir ./hosts/${arch});

      # build one host, choosing folder + system by isARM flag
      mkHost =
        host: isARM:
        let
          folder = if isARM then "arm" else "x86";
          system = if isARM then ARM else X86;
        in
        {
          "${host}" = lib.nixosSystem {
            specialArgs = {
              inherit
                inputs
                outputs
                isARM
                system
                ;
              lib = nixpkgs.lib.extend (
                # INFO: Extend lib with lib.custom; This approach allows lib.custom to propagate into hm
                self: super: {
                  custom = import ./lib { inherit (nixpkgs) lib; };
                }
              );
            };
            modules = [
              { nixpkgs.overlays = [ self.overlays.default ]; }

              # Import secrets
              ./modules/global/secret-spec.nix
              ./secrets.nix

              # Host-specific configuration
              ./hosts/${folder}/${host}
            ];
          };
        };

      # Invoke mkHost for each host config that is declared for either X86 or ARM
      mkHostConfigs =
        hosts: isARM: lib.foldl (acc: set: acc // set) { } (lib.map (host: mkHost host isARM) hosts);
    in
    {
      overlays = import ./overlays { inherit inputs; };

      # now point at x86 *and* arm directories explicitly
      nixosConfigurations =
        (mkHostConfigs (readHosts "x86") false) // (mkHostConfigs (readHosts "arm") true);

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

      ## SHELL ##

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        {
          default = pkgs.mkShell {
            nativeBuildInputs =
              with pkgs;
              [
                # Basic nix tools
                nix
                nixos-rebuild
                home-manager
                nh
                # Git and git-crypt
                git
                git-crypt
                gnupg
                gpg-tui
                # Shells
                fish
                bash
                # Config tools
                dconf2nix
                # Network tools
                curl
                wget
                # System tools
                coreutils
                findutils
                gzip
                zstd
                # Text editors
                micro
                # microsoft-edit
                # Diagnostics
                inxi
                pciutils
                usbutils
                lshw
              ]
              ++ [
                inputs.yay.packages.${system}.default # My yay.nix tool
              ];

            NIX_CONFIG = "experimental-features = nix-command flakes";

            shellHook = ''
              clear
              echo "Development shell initialized"
              echo -e "Run '\033[1;34myay rebuild\033[0m' to rebuild your system"

              # Set FLAKE to the current working directory
              export FLAKE="$PWD"
              echo -e "FLAKE environment variable is set to: \033[1;34m$FLAKE\033[0m"
            '';
          };
        }
      );
    };
}
