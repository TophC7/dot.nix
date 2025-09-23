{
  lib,
  ...
}:
let
  consts = {
    DATA_BASE_PATH = "/hold";
  };
in
{
  imports = lib.custom.scanPaths ./.;

  # Make constants available to all imported modules
  _module.args.consts = consts;
}
