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
  imports = lib.fs.scanPaths ./.;

  # Make constants available to all imported modules
  _module.args.consts = consts;

  # Newt Networks
  services.newt = {
    extraNetworks = [
      "adguard"
      "komodo"
      "pangolin"
    ];
  };
}
