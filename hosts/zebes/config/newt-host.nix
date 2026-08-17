{
  lib,
  pkgs,
  secrets,
  ...
}:
let
  name = "newt-host";
  env = secrets.service.newt-zebes-host;
  waitForPangolin = pkgs.writeScript "wait-for-pangolin" ''
    #!${lib.getExe pkgs.fish}
    set attempts 60
    while test $attempts -gt 0
      if ${lib.getExe pkgs.getent} ahosts pangolin.ryot.foo >/dev/null 2>&1
        exit 0
      end
      set attempts (math $attempts - 1)
      ${pkgs.coreutils}/bin/sleep 1
    end

    echo "pangolin.ryot.foo did not become resolvable within 60 seconds" >&2
    exit 1
  '';
in
{
  virtualisation.oci-stacks.${name} = {
    network.enable = false;
    containers = {
      "newt-host" = {
        image = "fosrl/newt:latest";
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

  # Docker snapshots host DNS when creating a container. Wait for DHCP DNS first.
  systemd.services =
    lib.genAttrs
      [
        "docker-newt"
        "docker-newt-host"
      ]
      (_: {
        serviceConfig.ExecStartPre = lib.mkBefore [ "${waitForPangolin}" ];
      });
}
