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
            isARM
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

          # Import secrets
          (customLib.relativeToRoot "modules/global/secret-spec.nix")
          (customLib.relativeToRoot "secrets.nix")

          # Host-specific configuration
          (customLib.relativeToRoot "hosts/${folder}/${host}")
        ];
      };
    };

  # Invoke mkHost for each host config that is declared for either X86 or ARM
  mkHostConfigs =
    hosts: isARM: lib.foldl (acc: set: acc // set) { } (lib.map (host: mkHost host isARM) hosts);
in
{
  flake.nixosConfigurations =
    (mkHostConfigs (readHosts "x86") false) // (mkHostConfigs (readHosts "arm") true);
}
