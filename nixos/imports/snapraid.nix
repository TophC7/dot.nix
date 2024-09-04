{ pkgs, ... }:

{
    environment.etc."snapraid-runner.conf".text = builtins.readFile ../pkgs/snapraid-runner/snapraid-runner.conf;
    environment.etc."snapraid.conf".text = builtins.readFile ./snapraid.conf;

    # Enable the SnapRAID service
    # services.snapraid = {
    #     enable = true;
    #     configFile = "/etc/snapraid.conf";
    # };
}
