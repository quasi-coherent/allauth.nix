{ lib, ... }:
{
  mkAllAuthCli =
    {
      pkgs,
      allauth-venv,
      projectDir,
      projectName,
    }:
    pkgs.callPackage ./cli.nix { inherit allauth-venv projectDir projectName; };

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
}
