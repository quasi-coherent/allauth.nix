{ aa, den, ... }:
let
  inherit (den.aspects.allauthConfig) projectName;
in
{
  den.aspects.allauth.includes = [
    den.aspects.allauthConfig

    aa.base
    aa.celery
    aa.dummyRootMount
    aa.gunicorn
    aa.mysql
    aa.nginx
    aa.redis
    aa.user
  ];

  den.schema.flake-system.includes = [
    den.aspects.allauth
    den.aspects.allauthConfig
  ];

  den.hosts.aarch64-linux.allauth = {
    intoAttr = [
      "nixosConfigurations"
      projectName
      "aarch64-linux"
    ];
  };

  den.hosts.x86_64-linux.allauth = {
    intoAttr = [
      "nixosConfigurations"
      projectName
      "x86_64-linux"
    ];
  };
}
