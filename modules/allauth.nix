{ aa, den, ... }:
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
}
