{
  secrets,
  ...
}:
let
  name = "filerun";
  env = secrets.service.filerun;
in
{
  virtualisation.oci-stacks.${name} = {
    containers = {
      "${name}-db" = {
        image = "mariadb:10.11";
        environment = env;
        volumes = [ "/fast/filerun/db:/var/lib/mysql:rw" ];
        user = "1000:1004";
        log-driver = "journald";
        extraOptions = [
          "--network=${name}"
          "--network-alias=db"
        ];
      };

      "${name}-web" = {
        image = "filerun/filerun:8.1";
        environment = env;
        volumes = [
          "/tank/:/tank:rw"
          "/fast/filerun/html:/var/www/html:rw"
          "/tank/user-files:/user-files:rw"
        ];
        dependsOn = [ "${name}-db" ];
        user = "root";
        log-driver = "journald";
        extraOptions = [
          "--network=${name}"
          "--network-alias=web"
          "--expose=80"
        ];
      };
    };
    description = "FileRun file management stack";
  };
}
