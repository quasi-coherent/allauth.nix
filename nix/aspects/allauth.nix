{ aa, ... }:
{
  aa.allauth.includes = [
    aa.filesystem
    aa.systemEnv
    aa.network
    aa.user
    aa.ssh
    aa.secrets
    aa.mysql
    aa.redis
    aa.nginx
    aa.gunicorn
    aa.celery
  ];
}
