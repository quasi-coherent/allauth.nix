_: {
  den.aspects.mysql.nixos =
    { config, pkgs, ... }:
    let
      conf = config.allauthConf;
    in
    {
      services = {
        mysql = {
          enable = true;
          package = pkgs.mariadb_114;
          settings.mysqld = {
            bind-address = "127.0.0.1";
            character-set-server = "utf8mb4";
            collation-server = "utf8mb4_unicode_ci";
          };
          ensureDatabases = [ conf.dbName ];
          ensureUsers = [
            {
              name = conf.user;
              ensurePermissions."${conf.dbName}.*" = "ALL PRIVILEGES";
            }
          ];
        };

        mysqlBackup = {
          enable = true;
          databases = [ conf.dbName ];
          compressionAlg = "zstd";
          compressionLevel = 8;
        };
      };
    };

  den.aspects.redis.nixos =
    { config, ... }:
    let
      conf = config.allauthConf;
    in
    {
      # It's super confusing how things are named if you call the server something
      # other than "".  With "" everything gets the name "redis".  This is not a
      # very good `services` implementation because this fact is non-obvious and a
      # default you can't change.
      services.redis.servers."" = {
        enable = true;
        group = conf.group;
        bind = "localhost";
        port = 6379;
        unixSocket = conf.redisSock;
      };
    };
}
