{
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
  atypes = (import ../lib).types { inherit lib; };
in
{
  imports = [
    ./discord.nix
    ./plugins.nix
  ];

  options.allauth.app = {
    projectName = mkOption {
      type = types.str;
      default = "allauth";
      description = "Name to identify this specific AA project.";
    };
    siteName = mkOption {
      type = types.str;
      default = "Alliance Auth";
      description = "SITE_NAME shown in the UI.";
    };
    siteUrl = mkOption {
      type = types.str;
      default = "";
      example = "https://auth.allauth.space";
      description = "Base URL";
    };
    debug = {
      type = types.bool;
      default = false;
      description = "Enable debug mode in the AA app.";
    };
    finalInstalledApps = mkOption {
      type = types.listOf types.str;
      default = [ ];
      internal = true;
    };
    finalStaticEnvVars = mkOption {
      type = types.attrsOf types.str;
      default = { };
      internal = true;
    };
    finalSopsEnvVarKeys = mkOption {
      type = types.attrsOf types.str;
      default = { };
      internal = true;
    };
    finalBeatConfig = mkOption {
      type = types.listOf atypes.beatScheduleType;
      default = [ ];
      internal = true;
    };
  };
}
