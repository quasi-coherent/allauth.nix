{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.allauth.addOns.discord = {
    enable = mkEnableOption "discord";
    module = mkOption {
      type = types.str;
      default = "allianceauth.services.modules.discord";
      readOnly = true;
      internal = true;
    };
    syncNames = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable this to have a user's Discord nickname changed to their main
        in-game character's name.
      '';
    };
    tasks = mkOption {
      type =
        with types;
        listOf (submodule {
          options = {
            taskType = mkOption {
              type = enum [
                "update_all_groups"
                "update_all_nicknames"
                "update_all_usernames"
                "update_all"
              ];
              description = "The task for the AA Discord service to perform.";
              default = "update_all";
            };
            cronExpr = mkOption {
              type = str;
              description = "A crontab expression for the scheduling of this task.";
              default = "0 */12 * * *";
            };
          };
        });
      default = [ ];
    };
  };

  config =
    let
      cfg = config.allauth.addOns.discord;
      siteUrl = config.allauth.siteUrl;
    in
    lib.mkIf cfg.enable {
      allauth.build = {
        finalInstalledApps = [ cfg.module ];
        finalStaticEnvVars = {
          DISCORD_ENABLED = "true";
          DISCORD_CALLBACK_URL = "${siteUrl}/discord/callback/";
          DISCORD_SYNC_NAMES = if cfg.syncNames then "True" else "False";
        };
        finalSopsEnvVarKeys = {
          DISCORD_GUILD_ID = "discord_guild_id";
          DISCORD_APP_ID = "discord_app_id";
          DISCORD_APP_SECRET = "discord_app_secret";
          DISCORD_BOT_TOKEN = "discord_bot_token";
        };
        finalBeatConfig = map (task: {
          name = "discord.${task.taskType}";
          task = "discord.${task.taskType}";
          schedule = task.cronExpr;
        }) cfg.tasks;
      };
    };
}
