{
  description = "NixOS ISO configurations based on dot.nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    dot-nix = {
      url = "github:tophc7/dot.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  ## TODO: Add a github action to automatically create iso releases

  outputs =
    {
      self,
      nixpkgs,
      dot-nix,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;

      # Merge inputs with dot-nix inputs
      allInputs = inputs // dot-nix.inputs;

      # Define supported systems
      ARM = "aarch64-linux";
      X86 = "x86_64-linux";

      systems = [
        ARM
        X86
      ];

      # Helper to create ISO configurations
      mkIso =
        name: system: modules:
        lib.nixosSystem {
          inherit system;
          specialArgs = {
            inputs = allInputs; # Pass merged inputs as 'inputs'
            outputs = dot-nix.outputs; # Pass main flake outputs
            inherit system;
            isARM = system == ARM;
            lib = nixpkgs.lib.extend (
              self: super: {
                custom = import "${dot-nix}/lib" { inherit (nixpkgs) lib; };
              }
            );
          };

          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            ./not-secrets.nix
            ./default.nix
          ] ++ modules;
        };

      # Generate configurations for all system/type combinations
      mkConfigurations =
        let
          configs = lib.flatten (
            lib.map (
              system:
              let
                archSuffix = if system == ARM then "arm" else "x86";
              in
              [
                {
                  name = "server-iso-${archSuffix}";
                  inherit system;
                  modules = [ ./dist/server.nix ];
                }
                {
                  name = "desktop-iso-${archSuffix}";
                  inherit system;
                  modules = [ ./dist/desktop.nix ];
                }
              ]
            ) systems
          );
        in
        lib.listToAttrs (
          lib.map (config: {
            name = config.name;
            value = mkIso config.name config.system config.modules;
          }) configs
        );

      # Generate packages for all systems
      mkPackages =
        system:
        let
          archSuffix = if system == ARM then "arm" else "x86";
        in
        {
          "server-iso-${archSuffix}" =
            self.nixosConfigurations."server-iso-${archSuffix}".config.system.build.isoImage;
          "desktop-iso-${archSuffix}" =
            self.nixosConfigurations."desktop-iso-${archSuffix}".config.system.build.isoImage;
        };
    in
    {
      nixosConfigurations = mkConfigurations;

      # Easy build commands for each architecture
      packages = lib.genAttrs systems mkPackages;

      # Pass through the main flake's outputs (optional)
      inherit (dot-nix.outputs) overlays;
    };
}
