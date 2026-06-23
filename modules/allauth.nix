{
  config,
  den,
  inputs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.allauth;
in
{
  imports = [ ./add-ons ];

  options.allauth = {
    projectName = mkOption {
      type = types.str;
      default = "allauth";
      description = "Name to identify this specific AA project.";
    };
    projectDir = mkOption {
      type = types.str;
      default = "/var/lib/allauth/${cfg.projectName}";
      internal = true;
      readOnly = true;
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
    sopsFile = mkOption {
      type = with types; either str path;
      description = ''
        Path to the file containing sops secrets.

        This is required because the ESI/Django secrets are, at least.
      '';
    };
    includes = mkOption {
      type = with types; listOf (attrsOf raw);
      default = [ ];
      description = ''
        List of den aspects to add to the `includes` field of the output aspect.
      '';
    };
    debug = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable debug mode.";
    };
  };

  config = {
    den.aspects.allauthConfig =
      let
        inherit (cfg)
          projectDir
          projectName
          sopsFile
          debug
          ;

        webDir = "/var/www/${projectName}";
        user = "${projectName}-admin";
        group = "${projectName}-admins";
        dbName = "${projectName}_db";

        beatConfig = cfg.build.finalBeatConfig;

        staticEnvVars =
          cfg.build.finalStaticEnvVars
          // {
            AA_SITE_NAME = cfg.siteName;
            AA_SITE_URL = cfg.siteUrl;
            AA_STATIC_ROOT = "${webDir}/static";
            AA_LOG_DIR = "${projectDir}/log";
            AA_DB_NAME = dbName;
            AA_DB_USER = user;
            AA_DEBUG = debug;
            AA_EXTRA_INSTALLED_APPS = lib.concatStringsSep "," cfg.build.finalInstalledApps;
          }
          // lib.optionalAttrs (beatConfig != [ ]) {
            AA_BEAT_JSON = builtins.toJSON beatConfig;
          };

        envKeyMap = cfg.build.finalSopsEnvVarKeys // {
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
          sopsFile
          user
          webDir
          ;

        projectValues.env = staticEnvVars;
        projectSecretValues = {
          inherit envKeyMap sopsFile;
        };

        packages =
          { pkgs, ... }:
          let
            allauth-cli = (import ./lib { inherit inputs; }).mkAllAuthCli {
              inherit pkgs projectDir projectName;
            };
          in
          {
            "${projectName}-cli" = allauth-cli;
          };

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
              sopsFile = mkOption {
                type = with types; either str path;
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

    den.aspects.${cfg.projectName} = {
      includes = cfg.includes ++ [ den.aspects.allauthConfig ];
    };

    den.schema.flake-system.includes = [ den.aspects.${cfg.projectName} ];

    den.hosts.x86_64-linux.${cfg.projectName} = {
      intoAttr = [
        "nixosConfigurations"
        "x64"
        cfg.projectName
      ];
    };

    den.hosts.aarch64-linux.${cfg.projectName} = {
      intoAttr = [
        "nixosConfigurations"
        "arm64"
        cfg.projectName
      ];
    };
  };
}
