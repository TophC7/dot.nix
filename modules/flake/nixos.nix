{
  self,
  inputs,
  lib,
  ...
}:
let
  inherit (inputs.nixpkgs) lib;
  customLib = import (self.outPath + "/lib") { inherit lib; };

  ARM = "aarch64-linux";
  X86 = "x86_64-linux";

  ## Host Config ##

  # read host-dirs under e.g. hosts/x86 or hosts/arm
  readHosts = arch: lib.attrNames (builtins.readDir (customLib.relativeToRoot "hosts/${arch}"));

  # build one host, choosing folder + system by isARM flag
  mkHost =
    hostName: isARM:
    let
      folder = if isARM then "arm" else "x86";
      system = if isARM then ARM else X86;

      # Import and evaluate the data modules to extract configuration
      pkgs = import inputs.nixpkgs { inherit system; };

      # Evaluate all data modules together (specs + implementations)
      dataEval = lib.evalModules {
        modules = [
          # Provide assertions option that evalModules expects
          { options.assertions = lib.mkOption { type = lib.types.listOf lib.types.unspecified; default = []; }; }

          # Import host spec and implementation
          (customLib.relativeToRoot "modules/global/host-spec.nix")
          (customLib.relativeToRoot "lib/hosts.nix")

          # Import secret spec and implementation
          (customLib.relativeToRoot "modules/global/secret-spec.nix")
          (customLib.relativeToRoot "lib/secrets.nix")
        ];
        specialArgs = {
          inherit pkgs lib;
        };
      };

      # Extract both host and secrets from the single evaluation
      host = dataEval.config.hostSpec.${hostName} or {};
      secrets = dataEval.config.secretsSpec;
    in
    {
      "${hostName}" = lib.nixosSystem {
        specialArgs = {
          inherit
            host
            inputs
            isARM
            secrets
            system
            ;
          outputs = self;
          lib = inputs.nixpkgs.lib.extend (
            # INFO: Extend lib with lib.custom; This approach allows lib.custom to propagate into hm
            self: super: {
              custom = import (customLib.relativeToRoot "lib") { inherit (inputs.nixpkgs) lib; };
            }
          );
        };
        modules = [
          { nixpkgs.overlays = [ self.overlays.default ]; }

          # Host-specific configuration
          (customLib.relativeToRoot "hosts/${folder}/${hostName}")
        ];
      };
    };

  # Invoke mkHost for each host config that is declared for either X86 or ARM
  mkHostConfigs =
    hosts: isARM:
    lib.foldl (acc: set: acc // set) { } (lib.map (hostName: mkHost hostName isARM) hosts);
in
{
  flake.nixosConfigurations =
    (mkHostConfigs (readHosts "x86") false) // (mkHostConfigs (readHosts "arm") true);
}
