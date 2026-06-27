{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
  atypes = (import ../lib).types { inherit lib; };
  cfg = config.allauth.services.discord;
  siteUrl = config.allauth.app.siteUrl;
in
{
  options.allauth.services.discord = {
    enable = mkEnableOption "discord";
    module = atypes.mkModuleOption "allianceauth.services.modules.discord";
    syncNames = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable this to have a user's Discord nickname changed to their main
        in-game character's name.
      '';
    };
    beatSchedule = mkOption {
      type = atypes.beatScheduleType;
      description = "Celery beat scheduler config.";
      default = { };
    };
  };

  config.allauth.app = lib.mkIf cfg.enable {
    finalInstalledApps = [ cfg.module ];
    finalStaticEnvVars = {
      DISCORD_ENABLED = "1";
      DISCORD_CALLBACK_URL = "${siteUrl}/discord/callback/";
      DISCORD_SYNC_NAMES = if cfg.syncNames then "True" else "False";
    };
    finalSopsEnvVarKeys = {
      DISCORD_GUILD_ID = "discord_guild_id";
      DISCORD_APP_ID = "discord_app_id";
      DISCORD_APP_SECRET = "discord_app_secret";
      DISCORD_BOT_TOKEN = "discord_bot_token";
    };
    finalBeatConfig = [ cfg.beatSchedule ];
  };
}
