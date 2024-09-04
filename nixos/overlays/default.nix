self: super:

let
    callPackage = super.callPackage;
in {
    snapraid-runner = callPackage ../pkgs/snapraid-runner { };
}