_: {
  den.aspects.nginx = {
    firewall.ports = [
      80
      443
    ];

    nixos =
      { config, ... }:
      let
        conf = config.allauthConf;
      in
      {
        services.nginx = {
          enable = true;
          recommendedProxySettings = true;
          recommendedGzipSettings = true;
          recommendedOptimisation = true;

          virtualHosts.${config.networking.hostName} = {
            default = true;
            locations."/static/".alias = "${conf.webDir}/static";
            locations."/media/".alias = "${conf.webDir}/media";
            # Proxy everything else to gunicorn.
            locations."/".proxyPass = "http://unix:${conf.gunicornSock}";
          };
        };

        # The nginx user needs to read/write to the socket file for gunicorn.
        # The easiest way to do that is put nginx in the group that owns that
        # directory.
        users.users.nginx.extraGroups = [ conf.group ];
      };
  };

  den.aspects.gunicorn.nixos =
    {
      config,
      aalib',
      ...
    }:
    let
      conf = config.allauthConf;
      aa-bin = aalib'.mkAllAuthBin { };
    in
    {
      systemd.tmpfiles.rules = [
        "d ${conf.webDir}/media   0750 ${conf.user} ${conf.group} -"
        "d ${conf.webDir}/static  0750 ${conf.user} ${conf.group} -"
        "d ${conf.projectDir}     0750 ${conf.user} ${conf.group} -"
        "d ${conf.projectDir}/log 0750 ${conf.user} ${conf.group} -"
      ];

      systemd.sockets.gunicorn = {
        description = "Unix socket for AA gunicorn server";
        wantedBy = [ "sockets.target" ];
        socketConfig = {
          ListenStream = conf.gunicornSock;
          SocketUser = conf.user;
          SocketGroup = conf.group;
        };
      };

      systemd.services.allauth-init = {
        description = "Initialization tasks for the AA app";
        requiredBy = [ "gunicorn.service" ];
        before = [ "gunicorn.service" ];
        environment = conf.staticEnv;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = conf.user;
          Group = conf.group;
          EnvironmentFile = config.sops.templates."allauth-secrets".path;
          WorkingDirectory = conf.projectDir;
          ExecStart = [
            "${aa-bin} migrate"
            "${aa-bin} collectstatic"
          ];
        };
      };

      systemd.services.gunicorn = {
        description = "gunicorn daemon";
        requires = [ "gunicorn.socket" ];
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        environment = config.allauth.staticEnv;
        serviceConfig = {
          Type = "notify";
          User = conf.user;
          Group = conf.group;
          WorkingDirectory = conf.projectDir;
          EnvironmentFile = config.sops.templates."allauth-secrets".path;
          ExecStart = "${aa-bin} web";
          ExecReload = "kill -s HUP $MAINPID";
          Restart = "always";
        };
      };
    };

  den.aspects.celery.nixos =
    {
      config,
      aalib',
      ...
    }:
    let
      conf = config.allauthConf;
      aa-bin = aalib'.mkAllAuthBin { };
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
        environment = conf.staticEnv;
        serviceConfig = {
          User = conf.user;
          Group = conf.group;
          WorkingDirectory = conf.projectDir;
          EnvironmentFile = config.sops.templates."allauth-secrets".path;
          ExecStart = "${aa-bin} celery-worker";
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
        environment = conf.staticEnv;
        serviceConfig = {
          User = conf.user;
          Group = conf.group;
          WorkingDirectory = conf.projectDir;
          ExecStart = "${aa-bin} celery-services";
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
        environment = conf.staticEnv;
        serviceConfig = {
          User = conf.user;
          Group = conf.group;
          WorkingDirectory = conf.projectDir;
          ExecStart = "${aa-bin} celery-scheduler";
          EnvironmentFile = config.sops.templates."allauth-secrets".path;
          Restart = "on-failure";
        };
      };
    };
}
