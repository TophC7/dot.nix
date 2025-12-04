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
        "/fast/explorer:/cache:rw"
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
