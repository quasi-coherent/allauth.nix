{
  den,
  ...
}:
let
  inherit (den.aspects.allauthConfig)
    dbName
    group
    redisSock
    user
    ;
in
{
  aa.mysql = {
    nixos =
      { pkgs, ... }:
      {
        services = {
          mysql = {
            enable = true;
            package = pkgs.mariadb_114;
            bind = "localhost";
            configFile = ''
              [mysqld]
              character-set-server = utf8mb4
              collation-server     = utf8mb4_unicode_ci
            '';
            ensureDatabases = [ dbName ];
            ensureUsers.${user} = {
              ensurePermissions."${dbName}.*" = "ALL PRIVILEGES";
            };
          };

          mysqlBackup = {
            enable = true;
            databases = [ dbName ];
            compressionAlg = "zstd";
            compressionLevel = 8;
          };
        };
      };
  };

  aa.redis.nixos = {
    # It's super confusing how things are named if you call the server something
    # other than "".  With "" everything gets the name "redis".  This is not a
    # very good implementation, `nixpkgs.services.redis`, since this is
    # non-obvious and a default that cannot be changed.
    services.redis.servers."" = {
      enable = true;
      group = [ group ];
      bind = "localhost";
      port = 6379;
      unixSocket = redisSock;
    };
  };
}
