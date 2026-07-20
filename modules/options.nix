{
  flake-parts-lib,
  lib,
  ...
}:
let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) mkOption types;

  mkAppSecretOption =
    name:
    mkOption {
      type = types.str;
      default = name;
      description = "Sops secret key for the required value ${name}";
    };
in
{
  imports = [ ./plugins ];

  options.allauth = {
    workspaceRoot = mkOption {
      type = types.path;
      default = ../.;
      description = ''
        Path to a uv workspace that installs `AllAuth` configuration in the
        Python module specified in `allauth.settingsModule`.
      '';
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
      type = with types; lazyAttrsOf (nullOr str);
      default = { };
      example = {
        A_POSITIVE_INTEGER = "5";
      };
      description = "Non-secret environment variables to set.";
    };
    sopsEnvVars = mkOption {
      type = with types; lazyAttrsOf (nullOr str);
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
  };

  options.perSystem = mkPerSystemOption (
    { pkgs, ... }:
    {
      options.allauth = {
        pythonPackage = mkOption {
          type = types.package;
          default = pkgs.python314;
          description = ''
            Python package to use when building the Alliance Auth app.
          '';
        };
        extraOverlays = mkOption {
          type = with types; listOf raw;
          default = [ ];
          description = ''
            List of additional overlays to pass to the Python fileset builder.
          '';
        };
        targetSystem = mkOption {
          type = types.str;
          default = if pkgs.stdenvNoCC.buildPlatform.isAarch then "aarch64-linux" else "x86_64-linux";
          description = "The architecture of the target system.";
          readOnly = true;
        };
      };
    }
  );
}
