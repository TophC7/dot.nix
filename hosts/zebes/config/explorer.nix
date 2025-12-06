{
  secrets,
  ...
}:
let
  env = secrets.service.explorer-zebes;
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
        PUBLIC_URL = "https://store.ryot.foo";
        SESSION_SECRET = env.SESSION_SECRET;
      };
      volumes = [
        "/store/explorer/cache:/cache:rw"
        "/store/explorer/config:/config:rw"
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
