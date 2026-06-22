{
  aa,
  den,
  inputs,
  lib,
  ...
}:
{
  den.aspects.allauthConfig.includes = [
    aa.secrets
  ];

  aa.secrets.nixos =
    { config, projectSecretValues, ... }:
    let
      inherit (projectSecretValues) envKeyMap sopsFile;
      user = den.aspects.allauthConfig.user;
    in
    {
      imports = [ inputs.sops.nixosModules.sops ];

      sops = {
        defaultSopsFile = sopsFile;
        # Values in the attrset envKeyMap are the sops keys.
        secrets = lib.genAttrs (lib.attrValues envKeyMap) (_: { });
        # One env file rendered into tmpfs owned by the service user.
        templates."allauth-secrets" = {
          owner = user;
          path = "/run/secrets/allauth-secrets";
          content = lib.concatLines (
            lib.mapAttrsToList (env: secret: "${env}=${config.sops.placeholder.${secret}}") envKeyMap
          );
        };
      };
    };
}
