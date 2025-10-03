{ inputs, lib, self, ... }:
let
  customLib = import (self.outPath + "/lib") { inherit lib; };
in
{
  flake.overlays = import (customLib.relativeToRoot "overlays") { inherit inputs; };
}
