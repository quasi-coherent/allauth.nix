{
  config,
  inputs,
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
      type = types.package;
      default =
        (alib.mkAllAuthVenv' {
          inherit inputs;
          pkgs = inputs.nixpkgs.legacyPackages.${config.allauth.targetSystem};
        }).allauth-venv;
      defaultText = lib.literalMD "the default allauth virtualenv";
      description = ''
        Virtualenv providing the `aa` CLI's Python runtime.

        Defaults to the allauth virtualenv built by this flake.  A downstream
        flake may supply its own virtualenv (built from its own uv workspace
        depending on allauth) here to layer extra functionality, provided it
        still contains the allauth project package and a valid environment for
        the CLI subcommands.
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
