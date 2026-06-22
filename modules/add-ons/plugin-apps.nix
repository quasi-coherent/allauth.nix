{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;

  mkPluginOption =
    pyMod:
    mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "Enable the plugin ${pyMod}";
          module = mkOption {
            type = types.str;
            default = pyMod;
            readOnly = true;
          };
        };
      };
      default = { };
    };

  foldOp = acc: ps: acc ++ (lib.optional ps.enable ps.module);
in
{
  options.allauth.addOns = {
    autoGroups = mkPluginOption "allianceauth.eveonline.autogroups";
    corpStats = mkPluginOption "allianceauth.corputils";
    fleetActivityTracking = mkPluginOption "allianceauth.fleetactivitytracking";
    hrApps = mkPluginOption "allianceauth.hrapplications";
    fleetOps = mkPluginOption "allianceauth.optimer";
    permissionsAuditing = mkPluginOption "allianceauth.permissions_tool";
    shipReplacement = mkPluginOption "allianceauth.srp";
    structureTimers = mkPluginOption "allianceauth.timerboard";
  };

  config =
    let
      cfg = config.allauth.addOns;
    in
    {
      allauth.build.finalInstalledApps =
        lib.foldr foldOp
          [ ]
          [
            cfg.autoGroups
            cfg.corpStats
            cfg.fleetActivityTracking
            cfg.hrApps
            cfg.fleetOps
            cfg.permissionsAuditing
            cfg.shipReplacement
            cfg.structureTimers
          ];
    };
}
