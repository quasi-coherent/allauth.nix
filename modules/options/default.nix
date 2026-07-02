{
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  imports = [
    ./discord.nix
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
    settingsModule = mkOption {
      type = types.str;
      example = "mysite.settings";
      description = ''
        Importable Django settings module for this deployment, set as
        `DJANGO_SETTINGS_MODULE` for every runtime process.

        The module must wildcard-import the base settings and install a
        configured `AllianceAuthApp`:

        ```python
        from allauth_lib.settings import *
        from allauth_lib import AllianceAuthApp

        app = AllianceAuthApp(name = "My Auth")
        # ...app.var / add_plugin / add_service / celery_conf...
        app.install(globals())
        ```
      '';
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
    # The Nix→runtime value seam.  App structure (INSTALLED_APPS, celery beat
    # schedule) is owned by the Python `AllianceAuthApp`, not by Nix; these
    # options only carry runtime *values* for settings that read them from the
    # environment.
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
  };
}
