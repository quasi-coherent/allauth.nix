{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
  cfg = config.allauth.services.discord;
  siteUrl = config.allauth.app.siteUrl;
in
{
  options.allauth.services.discord = {
    # The discord app itself is installed Python-side with
    # `add_plugin("allianceauth.services.modules.discord")`; this option only
    # supplies the runtime values its settings read from the environment.
    enable = mkEnableOption "discord runtime values (secrets + static env)";
    syncNames = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable this to have a user's Discord nickname changed to their main
        in-game character's name.
      '';
    };
  };

  config.allauth.app = lib.mkIf cfg.enable {
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
  };
}
