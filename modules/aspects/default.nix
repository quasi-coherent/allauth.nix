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
    ./storage.nix
  ];

  # Aspect to gather project values and constants shared throughout the
  # configuration.
  #
  # To make the module options held by `allauthConfig` accessible, per the den
  # docs:
  # "The function-args style is required for `imports` not to be interpreted as
  # an aspect class."
  den.aspects.allauthConfig =
    { config, ... }:
    {
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
            staticEnv = mkOption {
              type = with types; attrsOf str;
              internal = true;
            };
            sopsEnv = mkOption {
              type = with types; attrsOf str;
              internal = true;
            };
          };
        }
      ];

      projectName = cfg.app.projectName;
      projectDir = "/var/lib/allauth/${config.projectName}";
      webDir = "/var/www/${config.projectName}";
      user = "${config.projectName}-admin";
      group = "${config.projectName}-admins";
      dbName = "${config.projectName}_db";

      # Static (non-secret) environment variables.
      # These are required by `allauth-lib`, declared without user involvement.
      staticEnv = cfg.app.finalStaticEnvVars // {
        DJANGO_SETTINGS_MODULE = cfg.app.settingsModule;
        AA_PROJECT_DIR = config.projectDir;
        AA_SITE_NAME = cfg.app.siteName;
        AA_SITE_URL = cfg.app.siteUrl;
        AA_STATIC_ROOT = "${config.webDir}/static";
        AA_LOG_DIR = "${config.projectDir}/log";
        AA_DB_NAME = config.dbName;
        AA_DB_USER = config.user;
        AA_DEBUG = if cfg.app.debug then "True" else "False";
      };

      # Same but for secret values.
      sopsEnv = cfg.app.finalSopsEnvVarKeys // {
        SECRET_KEY = "secret_key";
        ESI_SSO_CLIENT_ID = "esi_sso_client_id";
        ESI_SSO_CLIENT_SECRET = "esi_sso_client_secret";
        ESI_USER_CONTACT_EMAIL = "esi_user_contact_email";
      };
    };
}
