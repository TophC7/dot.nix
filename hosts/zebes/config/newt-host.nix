{
  secrets,
  ...
}:
let
  name = "newt-host";
  env = secrets.service.newt-zebes-host;
in
{
  virtualisation.oci-stacks.${name} = {
    network.enable = false;
    containers = {
      "newt-host" = {
        image = "fosrl/newt";
        cmd = [
          "--id"
          env.ID
          "--endpoint"
          "https://pangolin.ryot.foo"
          "--secret"
          env.SECRET
        ];

        log-driver = "journald";
        user = "root:root";

        extraOptions = [
          "--privileged"
          "--cap-add=NET_ADMIN"
          "--cap-add=SYS_MODULE"
          "--network=host"
        ];
      };
    };
    description = "Pangolin Newt running in host network mode";
  };
}
