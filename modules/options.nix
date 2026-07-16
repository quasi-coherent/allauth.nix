{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = [ ./plugins ];

  options.allauth = {
    includes = mkOption {
      type = with types; listOf (attrsOf raw);
      default = [ ];
      description = "List of den aspects to include on the final host aspect.";
    };
    project = {
      name = mkOption {
        type = types.str;
        default = "allauth";
        description = "Name of the project.";
      };
      root = mkOption {
        type = with types; either str path;
        default = ../../.;
        description = ''
          Root of the uv workspace used to build the runtime virtualenv.

          Defaults to this flake's own uv workspace, which is a minimal AA app.
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
          SECRET_KEY = "secret_key";
          ESI_SSO_CLIENT_ID = "esi_sso_client_id";
        };
      };
      debug = mkOption {
        type = types.bool;
        default = false;
        description = "Enable debug mode in the AA app.";
      };
    };
  };
}
