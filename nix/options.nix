{ config, lib, ... }:
let
  inherit (lib) mkOption types;
  mkAppSecretOption =
    name:
    mkOption {
      type = types.str;
      default = name;
      description = "Sops secret key for the required value ${name}";
    };
  mkDefOption = v: mkOption { default = v; };
in
{
  imports = [ ./plugins ];

  options.allauth = {
    name = mkOption {
      type = types.str;
      default = "allauth";
      description = "Name of the project.";
    };
    settingsModule = mkOption {
      type = types.str;
      default = "allauth.settings";
      example = "mysite.settings";
      description = ''
        Django settings module for this deployment, the value set as
            `DJANGO_SETTINGS_MODULE` for runtime processes.

            The module must wildcard-import the base settings and install a
            configured `AllAuth` instance:

            ```python
            from allauth.settings import *
            from allauth import AllAuth, AppPlugin, SiteConfig

            config = SiteConfig(site_name="Example", site_url="https://example.edu")

            app = AllAuth(config)
            app.with_plugin(AppPlugin("allianceauth.some.module"))

            app.install(globals())
          ```
      '';
    };
    sopsConfig = mkOption {
      type = types.submodule {
        options = {
          secretsFile = mkOption {
            type = with types; either str path;
            default = "/root/.sops/secrets/example.yaml";
            description = ''
              Path to the sops secret file.

              If a local path, the file will be added to the nix store.  To
              avoid, use a full string path.
            '';
          };
          ageSshKeyPaths = mkOption {
            type = with types; listOf str;
            default = [ ];
            description = "Automatically import SSH keys as age keys";
          };
          ageKeyFile = mkOption {
            type = types.str;
            default = "/var/lib/sops-nix/key.txt";
            description = ''
              Age private key file expected to be in the filesystem.
            '';
          };
          ageGenerateKey = mkOption {
            type = types.bool;
            default = false;
            description = "Generate a new key if the one above does not exist.";
          };
          appSecrets = {
            djangoSecretKey = mkAppSecretOption "secret_key";
            esiSsoClientId = mkAppSecretOption "esi_sso_client_id";
            esiSsoClientSecret = mkAppSecretOption "esi_sso_client_secret";
            esiUserContactEmail = mkAppSecretOption "esi_user_contact_email";
          };
        };
      };
    };
    staticEnvVars = mkOption {
      type = with types; lazyAttrsOf nullOr str;
      default = { };
      example = {
        A_POSITIVE_INTEGER = "5";
      };
      description = "Non-secret environment variables to set.";
    };
    sopsEnvVars = mkOption {
      type = with types; lazyAttrsOf nullOr str;
      default = { };
      description = ''
        Environment variables to set from a sops secret.

          The name is the environment key and the value is the key in the
          sops secret values file required by the module options.
      '';
      example = {
        DISCORD_APP_SECRET = "discord_app_secret";
      };
    };
    includes = mkOption {
      type = with types; listOf (attrsOf raw);
      default = [ ];
      description = "List of den aspects to include on the final host aspect.";
    };
    debug = mkOption {
      type = types.bool;
      default = false;
      description = "Enable debug mode in the AA app.";
    };
  };

  config =
    let
      cfg = config.allauth;
      sopsCfg = cfg.sopsConfig;
      projectName = cfg.name;
      projectDir = "/var/lib/allauth/${projectName}";
      webDir = "/var/www/${projectName}";
      user = "aaadmin";
      group = "aaadmin";
      dbName = "allauthdb";
      sopsSecretsFile = sopsCfg.secretsFile;
      ageSshKeyPaths = sopsCfg.ageSshKeyPaths;
      ageKeyFile = sopsCfg.ageKeyFile;
      ageGenerateKey = sopsCfg.ageGenerateKey;
      sopsEnv = cfg.sopsEnvVars // {
        SECRET_KEY = sopsCfg.appSecrets.djangoAppSecret;
        ESI_SSO_CLIENT_ID = sopsCfg.appSecrets.ssoClientId;
        ESI_SSO_CLIENT_SECRET = sopsCfg.appSecrets.ssoClientSecret;
        ESI_USER_CONTACT_EMAIL = sopsCfg.appSecrets.userContactEmail;
      };
      staticEnv = cfg.staticEnvVars // {
        DJANGO_SETTINGS_MODULE = cfg.settingsModule;
        AA_PROJECT_DIR = projectDir;
        AA_STATIC_ROOT = "${webDir}/static";
        AA_LOG_DIR = "${projectDir}/log";
        AA_DB_NAME = dbName;
        AA_DB_USER = user;
        AA_DEBUG = if cfg.debug then "True" else "False";
      };
    in
    {
      den.schema = {
        host.includes = cfg.includes;
        schema.conf.options.allauth-conf = {
          projectName = mkDefOption projectName;
          projectDir = mkDefOption projectDir;
          webDir = mkDefOption webDir;
          user = mkDefOption user;
          group = mkDefOption group;
          dbName = mkDefOption dbName;
          redisSock = mkDefOption "/run/redis/redis.sock";
          gunicornSock = mkDefOption "/run/gunicorn/gunicorn.sock";
          staticEnv = mkDefOption staticEnv;
          sopsEnv = mkDefOption sopsEnv;
          sopsSecretsFile = mkDefOption sopsSecretsFile;
          ageSshKeyPaths = mkDefOption ageSshKeyPaths;
          ageKeyFile = mkDefOption ageKeyFile;
          ageGenerateKey = mkDefOption ageGenerateKey;
        };
      };
    };
}
