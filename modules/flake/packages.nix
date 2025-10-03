{
  self,
  inputs,
  lib,
  ...
}:
let
  customLib = import (self.outPath + "/lib") { inherit lib; };
in
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };

      # Get all package directories from pkgs/
      packageDirs = builtins.attrNames (builtins.readDir (customLib.relativeToRoot "pkgs"));

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
    {
      packages = customPackages;
    };
}
