{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types;
  cfg = config.allauth.services.teamspeak3;
in
{
  options.allauth.services.teamspeak3 = {
    enable = mkEnableOption "teamspeak3";
    queryIp = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = ''
        The IP of the teamspeak server.

        Should be `TEAMSPEAK3_SERVER_IP` on the AA config side.
      '';
    };
    queryPort = mkOption {
      type = types.port;
      default = 10011;
      description = ''
        The port of the teamspeak server.

        Should be `TEAMSPEAK3_SERVER_PORT` on the AA config side.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    den.aspects.allauth.nixos.services.teamspeak3 = {
      enable = true;
      queryIP = cfg.queryIp;
      queryPort = cfg.queryPort;
    };
  };
}
