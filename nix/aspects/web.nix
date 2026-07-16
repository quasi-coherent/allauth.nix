{
  config,
  den,
  self,
  ...
}:
let
  cfg = config.allauth;

  inherit (den.aspects.allauthConfig)
    group
    gunicornSock
    projectDir
    staticEnv
    user
    webDir
    ;

  mkCli =
    pkgs:
    let
      venv = self.lib.mkAllAuthVenv {
        inherit pkgs;
        workspaceRoot = cfg.project.root;
      };
      inherit (venv) allauth-venv;
    in
    allauth-venv;
in
{
  den.aspects.web.includes = [
    den.aspects.nginx
    den.aspects.gunicorn
    den.aspects.celery
  ];

  den.aspects.nginx = {
    firewall.ports = [
      80
      443
    ];

    nixos =
      { config, ... }:
      {
        services.nginx = {
          enable = true;
          recommendedProxySettings = true;
          recommendedGzipSettings = true;
          recommendedOptimisation = true;

          virtualHosts.${config.networking.hostName} = {
            default = true;
            locations."/static/".alias = "${webDir}/static";
            locations."/media/".alias = "${webDir}/media";
            # Proxy everything else to gunicorn.
            locations."/".proxyPass = "http://unix:${gunicornSock}";
          };
        };

        # The nginx user needs to read/write to the socket file for gunicorn.
        # The easiest way to do that is put nginx in the group that owns that
        # directory.
        users.users.nginx.extraGroups = [ group ];
      };
  };

  den.aspects.gunicorn.nixos =
    {
      config,
      pkgs,
      ...
    }:
    let
      aa-cli = mkCli pkgs;
    in
    {
      systemd.tmpfiles.rules = [
        "d ${webDir}/media   0750 ${user} ${group} -"
        "d ${webDir}/static  0750 ${user} ${group} -"
        "d ${projectDir}     0750 ${user} ${group} -"
        "d ${projectDir}/log 0750 ${user} ${group} -"
      ];

      systemd.sockets.gunicorn = {
        description = "Unix socket for AA gunicorn server";
        wantedBy = [ "sockets.target" ];
        socketConfig = {
          ListenStream = gunicornSock;
          SocketUser = user;
          SocketGroup = group;
        };
      };

      systemd.services.allauth-init = {
        description = "Initialization tasks for the AA app";
        requiredBy = [ "gunicorn.service" ];
        before = [ "gunicorn.service" ];
        environment = staticEnv;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = user;
          Group = group;
          EnvironmentFile = config.sops.templates."allauth-secrets".path;
          WorkingDirectory = projectDir;
          ExecStart = [
            "${aa-cli}/bin/aa migrate"
            "${aa-cli}/bin/aa collectstatic"
          ];
        };
      };

      systemd.services.gunicorn = {
        description = "gunicorn daemon";
        requires = [ "gunicorn.socket" ];
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        environment = staticEnv;
        serviceConfig = {
          Type = "notify";
          User = user;
          Group = group;
          WorkingDirectory = projectDir;
          EnvironmentFile = config.sops.templates."allauth-secrets".path;
          ExecStart = "${aa-cli}/bin/aa web";
          ExecReload = "kill -s HUP $MAINPID";
          Restart = "always";
        };
      };
    };

  den.aspects.celery.nixos =
    {
      config,
      pkgs,
      ...
    }:
    let
      aa-cli = mkCli pkgs;
    in
    {
      systemd.services.celery-worker = {
        description = "Celery workers for the AA app";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "allauth-init.service"
        ];
        requires = [ "allauth-init.service" ];
        environment = staticEnv;
        serviceConfig = {
          User = user;
          Group = group;
          WorkingDirectory = projectDir;
          EnvironmentFile = config.sops.templates."allauth-secrets".path;
          ExecStart = "${aa-cli}/bin/aa celery-worker";
          Restart = "on-failure";
        };
      };

      systemd.services.celery-worker-services = {
        description = "Services queue for the AA app";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "allauth-init.service"
        ];
        requires = [ "allauth-init.service" ];
        environment = staticEnv;
        serviceConfig = {
          User = user;
          Group = group;
          WorkingDirectory = projectDir;
          ExecStart = "${aa-cli}/bin/aa celery-services";
          EnvironmentFile = config.sops.templates."allauth-secrets".path;
          Restart = "on-failure";
        };
      };

      systemd.services.celery-scheduler = {
        description = "AA celery beat scheduler";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "allauth-init.service"
        ];
        requires = [ "allauth-init.service" ];
        environment = staticEnv;
        serviceConfig = {
          User = user;
          Group = group;
          WorkingDirectory = projectDir;
          ExecStart = "${aa-cli}/bin/aa celery-scheduler";
          EnvironmentFile = config.sops.templates."allauth-secrets".path;
          Restart = "on-failure";
        };
      };
    };
}
