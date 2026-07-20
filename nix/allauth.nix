{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (import ./lib { inherit inputs lib; }) mkApp;

  mkDefOption = v: lib.mkOption { default = v; };
in
{
  imports = [
    ../modules/aspect.nix
    ../modules/options.nix
    inputs.den.flakeModules.default
  ];

  den.schema.conf.options.allauthConf =
    let
      cfg = config.allauth;
      sopsCfg = cfg.sopsConfig;
      workspaceRoot = cfg.workspaceRoot;
      projectDir = "/var/lib/allauth";
      webDir = "/var/www/allauth";
      user = "aaadmin";
      group = "aaadmin";
      dbName = "allauthdb";
      sopsSecretsFile = sopsCfg.secretsFile;
      ageSshKeyPaths = sopsCfg.ageSshKeyPaths;
      ageKeyFile = sopsCfg.ageKeyFile;
      ageGenerateKey = sopsCfg.ageGenerateKey;
      sopsEnv = cfg.sopsEnvVars // {
        SECRET_KEY = sopsCfg.appSecrets.djangoSecretKey;
        ESI_SSO_CLIENT_ID = sopsCfg.appSecrets.esiSsoClientId;
        ESI_SSO_CLIENT_SECRET = sopsCfg.appSecrets.esiSsoClientSecret;
        ESI_USER_CONTACT_EMAIL = sopsCfg.appSecrets.esiUserContactEmail;
      };
      staticEnv = cfg.staticEnvVars // {
        DJANGO_SETTINGS_MODULE = cfg.settingsModule;
        AA_PROJECT_DIR = projectDir;
        AA_STATIC_ROOT = "${webDir}/static";
        AA_LOG_DIR = "${projectDir}/log";
        AA_DB_NAME = dbName;
        AA_DB_USER = user;
      };
    in
    {
      workspaceRoot = mkDefOption workspaceRoot;
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

  perSystem =
    { pkgs, ... }:
    let
      inherit (config.allauth) workspaceRoot app;
      inherit (app) extraOverlays pythonPackage;

      mkApp' = mkApp pkgs;
    in
    {
      _module.args.allauth-bin =
        (mkApp' {
          inherit workspaceRoot extraOverlays;
          python = pythonPackage;
        }).allauth-bin;
    };
}
