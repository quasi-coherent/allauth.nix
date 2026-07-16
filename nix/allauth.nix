{
  config,
  den,
  lib,
  sopsModule,
  import-tree,
  ...
}:
let
  cfg = config.allauth;
in
{
  imports = [
    (import-tree ./aspects)
  ];

  den.aspects.allauth = {
    includes = cfg.includes ++ [
      den.aspects.allauthConfig
      den.aspects.base
      den.aspects.storage
      den.aspects.web
    ];

    nixos =
      {
        config,
        pkgs,
        ...
      }:
      {
        imports = [ sopsModule ];

        environment.systemPackages = [
          pkgs.age
          pkgs.emacs30
          pkgs.fd
          pkgs.git
          pkgs.jq
          pkgs.ripgrep
          pkgs.sd
          pkgs.sops
          pkgs.openssh
        ];

        # Without this the config fails to evaluate.
        fileSystems = lib.mkDefault {
          "/" = {
            device = "none";
            fsType = "tmpfs";
          };
        };

        sops =
          let
            env = den.aspects.allauthConfig.sopsEnv;

            # To make, e.g., `sops.secrets = { some_secret = { }; };`:
            secrets = lib.genAttrs (lib.attrValues env) (_: { });

            templates."allauth-secrets" = {
              owner = den.aspects.allauthConfig.user;
              path = "/run/secrets/allauth-secrets";
              content = lib.concatLines (
                lib.mapAttrsToList (env: secret: "${env}=${config.sops.placeholder.${secret}}") env
              );
            };
          in
          {
            inherit secrets templates;
          };
      };
  };
}
