{ den, ... }:
{
  imports = [ ./lib ];

  den.aspects.allauth.includes = [
    den.aspects.celery
    den.aspects.filesystem
    den.aspects.global
    den.aspects.gunicorn
    den.aspects.mysql
    den.aspects.network
    den.aspects.nginx
    den.aspects.redis
    den.aspects.secrets
    den.aspects.ssh
    den.aspects.user
  ];
}
