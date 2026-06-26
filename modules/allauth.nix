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
  imports = [
    ./aspects
    ./options
  ];

  options.allauth = {
    sops = mkOption {
      type = with types; attrsOf raw;
      default = { };
      description = ''
        Module options for sops.

        This module expects a sops secrets file and for it to have certain
        contents depending on what is enabled.

        For example, any AA application needs the ESI SSO client ID and
        secret, and so these always must be found in the sops secret because
        this module expects that.

        Additional plugins and services may have their own set of secret values,
        which should exist in the file as well if the plugin or service is
        enabled.
      '';
    };
    fileSystems = mkOption {
      type = with types; attrsOf raw;
      default = { };
      description = ''
        Configuration for filesystem mountpoints.

        A nixosSystem must have at least the root directory configured to be able
        to evaluate.  This could be provided indirectly through more elaborate
        means (e.g., disko) or the plain `fileSystems` option can be defined
        inline here.
      '';
    };
    systemPackages = mkOption {
      type = with types; listOf package;
      default = [ ];
      description = ''
        List of packages to install systemwide.
      '';
    };
    includes = mkOption {
      type = with types; listOf (attrsOf raw);
      default = [ ];
      description = ''
        Additional aspects to include in the final, main aspect.
      '';
    };
    targetSystem = mkOption {
      type =
        with types;
        enum [
          "x86_64-linux"
          "aarch64-linux"
        ];
      default = "aarch64-linux";
      description = ''
        The architecture of the system where this configuration will apply.
      '';
    };
  };

  config = {
    den.aspects.allauth = {
      includes = [
        den.aspects.allauthConfig
        den.aspects.base
        den.aspects.storage
        den.aspects.web
      ]
      ++ cfg.includes;

      imports = [
        inputs.sops.nixosModules.sops
      ];

      nixos =
        {
          config,
          pkgs,
          projectSecretValues,
          ...
        }:
        {
          environment.systemPackages = cfg.systemPackages ++ [
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

          fileSystems = lib.mkIf (cfg.fileSystems != { }) {
            inherit (cfg) fileSystems;
          };

          sops =
            let
              inherit (projectSecretValues) env;

              # Values in the attrset `env` are the sops keys.
              secrets = lib.genAttrs (lib.attrValues env) (_: { });
              # One env file rendered into tmpfs owned by the service user.
              templates."allauth-secrets" = {
                owner = den.aspects.allauthConfig.user;
                path = "/run/secrets/allauth-secrets";
                content = lib.concatLines (
                  lib.mapAttrsToList (env: secret: "${env}=${config.sops.placeholder.${secret}}") env
                );
              };
            in
            cfg.sops // { inherit secrets templates; };
        };
    };
  };
}
