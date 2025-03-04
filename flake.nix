{
  description = "Toph's Nix-Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # The next two are for pinning to stable vs unstable regardless of what the above is set to
    # This is particularly useful when an upcoming stable release is in beta because you can effectively
    # keep 'nixpkgs-stable' set to stable for critical packages while setting 'nixpkgs' to the beta branch to
    # get a jump start on deprecation changes.
    # See also 'stable-packages' and 'unstable-packages' overlays at 'overlays/default.nix"
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # NixOs hardware flakes
    hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # VM tools
    nixvirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
    };
    # TODO: theming
    # stylix.url = "github:danth/stylix/release-24.11";
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
            modules = [ ./hosts/nixos/${host} ];
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

      #
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
        in
        lib.packagesFromDirectoryRecursive {
          callPackage = lib.callPackageWith pkgs;
          directory = ./pkgs/common;
        }
      );
    };
}
