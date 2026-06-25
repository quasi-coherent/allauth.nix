{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (import ./lib { inherit lib; }) beatScheduleType;
  cfg = config.allauth;
in
{
  imports = [
    ./plugins.nix
    ./services
  ];

  options.allauth = {
    projectName = mkOption {
      type = types.str;
      default = "allauth";
      description = "Name to identify this specific AA project.";
    };
    siteName = mkOption {
      type = types.str;
      default = "Alliance Auth";
      description = "SITE_NAME shown in the UI.";
    };
    siteUrl = mkOption {
      type = types.str;
      default = "";
      example = "https://auth.allauth.space";
      description = "Base URL";
    };
    sopsConfig = mkOption {
      type = with types; lazyAttrsOf raw;
      description = ''
        Module options for sops to be merged with `sops.secrets` that are
        automatically defined by a requirement of the AA app.
      '';
    };
    debug = {
      type = types.bool;
      default = false;
      description = "Enable debug mode in the AA app.";
    };
    targetSystem = {
      type = types.str;
      default = "x86_64-linux";
      description = ''
        The architecture of the system where this will be deployed.
      '';
    };
    finalInstalledApps = mkOption {
      type = types.listOf types.str;
      default = [ ];
      internal = true;
    };
    finalStaticEnvVars = mkOption {
      type = types.attrsOf types.str;
      default = { };
      internal = true;
    };
    finalSopsEnvVarKeys = mkOption {
      type = types.attrsOf types.str;
      default = { };
      internal = true;
    };
    finalBeatConfig = mkOption {
      type = types.listOf beatScheduleType;
      default = [ ];
      internal = true;
    };
  };

  config = {
    den.aspects.allauthConfig =
      let
        inherit (cfg)
          debug
          projectName
          siteName
          siteUrl
          sopsConfig
          targetSystem
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
          projectDir
          projectName
          sopsConfig
          targetSystem
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
              sopsConfig = mkOption {
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
              targetSystem = mkOption {
                type = types.str;
                internal = true;
              };
            };
          }
        ];
      };
  };
}
