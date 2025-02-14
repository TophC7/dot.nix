{
  services = {
    db.service = {
      image = "mariadb:10.11";
      user = "1000:1004";
      environment = {
        MYSQL_ROOT_PASSWORD = "pHUlPjDwhfpfAJPlF/FYN8q5w2R+0/U4aosJ5FOBPIejHkmm";
        MYSQL_USER = "admin";
        MYSQL_PASSWORD = "m3kItsvjLTYWtYX1TQLxwAKBWDVnWsezPR3vtVS+rsHUlazY";
        MYSQL_DATABASE = "filerun";
      };
      volumes = [
        "/pool/filerun/db:/var/lib/mysql"
      ];
    };

    web.service = {
      image = "filerun/filerun:8.1";
      user = "root";
      tty = true;
      environment = {
        FR_DB_HOST = "db";
        FR_DB_PORT = "3306";
        FR_DB_NAME = "filerun";
        FR_DB_USER = "admin";
        FR_DB_PASS = "m3kItsvjLTYWtYX1TQLxwAKBWDVnWsezPR3vtVS+rsHUlazY";
        APACHE_RUN_USER = "toph";
        APACHE_RUN_USER_ID = "1000";
        APACHE_RUN_GROUP = "ryot";
        APACHE_RUN_GROUP_ID = "1004";
      };
      depends_on = [ "db" ];
      ports = [ "8181:80" ];
      volumes = [
        "/pool/filerun/html:/var/www/html"
        "/pool/filerun/user-files:/user-files"
        "/pool/:/pool"
      ];
    };
  };
}
