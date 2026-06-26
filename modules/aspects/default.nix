{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.allauth;
in
{
  imports = [
    (inputs.den.namespace "aa" true)
    ./web.nix
    ./base.nix
    ./den.nix
    ./secrets.nix
    ./storage.nix
  ];

  den.aspects.allauthConfig =
    let
      inherit (cfg.app)
        debug
        package
        projectName
        siteName
        siteUrl
        ;

      projectDir = "/var/lib/allauth/${projectName}";
      webDir = "/var/www/${projectName}";

      user = "${projectName}-admin";
      group = "${projectName}-admins";
      dbName = "${projectName}_db";

      beatConfig = cfg.finalBeatConfig;

      staticEnvVars =
        cfg.finalStaticEnvVars
        // {
          AA_SITE_NAME = siteName;
          AA_SITE_URL = siteUrl;
          AA_STATIC_ROOT = "${webDir}/static";
          AA_LOG_DIR = "${projectDir}/log";
          AA_DB_NAME = dbName;
          AA_DB_USER = user;
          AA_DEBUG = debug;
          AA_EXTRA_INSTALLED_APPS = lib.concatStringsSep "," cfg.finalInstalledApps;
        }
        // lib.optionalAttrs (beatConfig != [ ]) {
          AA_BEAT_JSON = builtins.toJSON beatConfig;
        };

      envKeyMap = cfg.finalSopsEnvVarKeys // {
        SECRET_KEY = "secret_key";
        ESI_SSO_CLIENT_ID = "esi_sso_client_id";
        ESI_SSO_CLIENT_SECRET = "esi_sso_client_secret";
        ESI_USER_CONTACT_EMAIL = "esi_user_contact_email";
      };
    in
    {
      inherit
        dbName
        debug
        group
        package
        projectDir
        projectName
        user
        webDir
        ;

      projectValues.env = staticEnvVars;
      projectSecretValues.env = envKeyMap;

      imports = [
        {
          options = {
            projectName = mkOption {
              type = types.str;
              internal = true;
            };
            projectDir = mkOption {
              type = types.str;
              internal = true;
            };
            webDir = mkOption {
              type = types.str;
              internal = true;
            };
            user = mkOption {
              type = types.str;
              internal = true;
            };
            group = mkOption {
              type = types.str;
              internal = true;
            };
            dbName = mkOption {
              type = types.str;
              internal = true;
            };
            package = mkOption {
              type = types.package;
              internal = true;
            };
            sops = mkOption {
              type = with types; lazyAttrsOf raw;
              internal = true;
            };
            redisSock = mkOption {
              type = types.str;
              default = "/run/redis/redis.sock";
              internal = true;
              readOnly = true;
            };
            gunicornSock = mkOption {
              type = types.str;
              default = "/run/gunicorn/gunicorn.sock";
              internal = true;
              readOnly = true;
            };
          };
        }
      ];
    };
}
