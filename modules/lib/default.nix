let
  mkAllAuthCli =
    {
      pkgs,
      package,
      projectDir,
      projectName,
    }:
    pkgs.callPackage ./cli.nix { inherit package projectDir projectName; };

  overrides = pkgs: pkgs.callPackage ./overrides.nix { };

  types = { lib }: {
    mkModuleOption =
      pyMod:
      lib.mkOption {
        type = lib.types.str;
        default = pyMod;
        description = "AA module path ${pyMod}.";
        readOnly = true;
      };

    beatScheduleType = lib.types.submodule {
      options = {
        key = lib.mkOption {
          type = lib.types.str;
          description = "Key in the CELERY_BEAT_SCHEDULE dict.";
        };
        task = lib.mkOption {
          type = lib.types.str;
          description = "Module path to the task being scheduled.";
        };
        schedule = lib.mkOption {
          type = lib.types.str;
          description = "Crontab expression for the schedule of this task.";
          default = "0 */12 * * *";
        };
      };
    };
  };

  mkAllAuthVenv' =
    {
      inputs,
      pkgs,
      workspaceRoot,
      ...
    }:
    let
      workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
        inherit workspaceRoot;
      };
      venv = pkgs.callPackage ./venv.nix {
        inherit (inputs) pyproject pyproject-build;
        inherit workspace;
      };
    in
    {
      inherit (venv)
        allauth
        allauth-venv
        fileset
        pyprojectOverrides
        ;
    };

  mkAllAuthShell' =
    {
      pkgs,
      allauth-venv,
      fileset,
      ...
    }:
    pkgs.callPackage ./devShell.nix { inherit allauth-venv fileset; };
in
{
  inherit
    mkAllAuthCli
    mkAllAuthVenv'
    mkAllAuthShell'
    overrides
    types
    ;
}
