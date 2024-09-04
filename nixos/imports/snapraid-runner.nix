{ pkgs, ... }:

{
    environment.etc."snapraid-runner.conf".text = builtins.readFile ../pkgs/snapraid-runner/snapraid-runner.conf;
}
