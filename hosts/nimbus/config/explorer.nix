{
  secrets,
  ...
}:
let
  env = secrets.service.explorer-nimbus;
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
        PUBLIC_URL = "https://tank.ryot.foo";
        SESSION_SECRET = env.SESSION_SECRET;
      };
      volumes = [
        "/fast/explorer/cache:/cache:rw"
        "/fast/explorer/config:/config:rw"
        "/repo:/mnt/repo:rw"
        "/tank:/mnt/tank:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=${name}"
        "--network-alias=${name}"
      ];
    };
    description = "Explorer file browser stack";
  };
}
