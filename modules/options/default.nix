{
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
  alib = import ../lib;
  atypes = alib.types { inherit lib; };
in
{
  imports = [
    ./discord.nix
    ./plugins.nix
  ];

  options.allauth.app = {
    package = mkOption {
      type = with types; nullOr package;
      default = null;
      description = ''
        Virtualenv providing the `aa` CLI's Python runtime.

        When `null` (the default) the virtualenv is built from
        `allauth.workspaceRoot` using each host's own `pkgs`, so it is produced
        for the correct architecture per host.

        A downstream flake may instead supply its own virtualenv (built from its
        own uv workspace depending on allauth) here to layer extra
        functionality, provided it still contains the allauth project package
        and a valid environment for the CLI subcommands.
      '';
    };
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
    debug = mkOption {
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
