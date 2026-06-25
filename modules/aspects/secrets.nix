{
  den,
  inputs,
  ...
}:
let
  inherit (den.aspects.allauthConfig) user sopsConfig;
in
{
  aa.secrets.nixos =
    {
      config,
      lib,
      projectSecretValues,
      ...
    }:
    let
      inherit (projectSecretValues) env;
      # Values in the attrset `env` are the sops keys.
      secrets = lib.genAttrs (lib.attrValues env) (_: { });
      # One env file rendered into tmpfs owned by the service user.
      templates."allauth-secrets" = {
        owner = user;
        path = "/run/secrets/allauth-secrets";
        content = lib.concatLines (
          lib.mapAttrsToList (env: secret: "${env}=${config.sops.placeholder.${secret}}") env
        );
      };
    in
    {
      imports = [ inputs.sops.nixosModules.sops ];

      sops = sopsConfig // {
        inherit secrets templates;
      };
    };
}
