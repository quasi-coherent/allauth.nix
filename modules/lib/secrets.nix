{ inputs, lib, ... }:
{
  den.aspects.secrets.nixos =
    { config, ... }:
    let
      conf = config.allauthConf;
    in
    {
      imports = [ inputs.sops.nixosModules.sops ];

      sops =
        let
          # The format is `sops.secrets = { some_secret = { }; };`.
          secrets = lib.genAttrs (lib.attrValues conf.sopsEnv) (_: { });
          templates."allauth-secrets" = {
            owner = conf.user;
            path = "/run/secrets/allauth-secrets";
            content = lib.concatLines (
              lib.mapAttrsToList (env: secret: "${env}=${config.sops.placeholder.${secret}}") conf.sopsEnv
            );
          };
        in
        {
          inherit secrets templates;

          defaultSopsFile = conf.sopsSecretsFile;
          age = {
            keyFile = conf.ageKeyFile;
            sshKeyPaths = conf.ageSshKeyPaths;
            generateKey = conf.ageGenerateKey;
          };
        };
    };
}
