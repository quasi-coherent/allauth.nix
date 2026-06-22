{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = [
    ./discord.nix
    ./plugin-apps.nix
  ];

  options.allauth.build = {
    finalInstalledApps = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of module paths for enabled plugins/services.";
      internal = true;
    };
    finalStaticEnvVars = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Mapping of env var key to static value.

        These are environment variables whose value can be statically defined
        without sops activation.
      '';
      internal = true;
    };
    finalSopsEnvVarKeys = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Mapping of env var key to sops key.

        These are environment variables whose value is a secret coming from sops
        activation.  The attrset maps the variable key to the sops key.
      '';
      internal = true;
    };
    finalBeatConfig = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "CELERYBEAT_SCHEDULE key.";
            };
            task = mkOption {
              type = types.str;
            };
            schedule = mkOption {
              type = types.str;
            };
          };
        }
      );
      default = [ ];
      description = ''
        Periodic tasks contributed by enabled features. Serialized to the
        AA_BEAT_JSON environment variable and parsed by settings/local.py.
      '';
      internal = true;
    };
  };
}
