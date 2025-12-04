{
  ...
}:
let
  name = "explorer";
in
{
  virtualisation.oci-stacks.${name} = {
    containers.${name} = {
      image = "nxzai/explorer:latest";
      environment = {
        GID = "1004";
        NODE_ENV = "production";
        UID = "1000";
      };
      volumes = [
        "/store/explorer:/cache:rw"
        "/store:/mnt/store:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=${name}"
        "--network-alias=${name}"
        "--expose=3000"
      ];
    };
    description = "Explorer file browser stack";
  };
}
