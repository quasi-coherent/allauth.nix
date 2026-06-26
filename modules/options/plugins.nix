{ config, lib, ... }:
let
  inherit (lib) mkEnableOption;
  atypes = (import ../lib).types { inherit lib; };
  cfg = config.allauth.plugins;
in
{
  options.allauth.plugins = {
    autoGroups = {
      enable = mkEnableOption "autoGroups";
      module = atypes.mkModuleOption "allianceauth.eveonline.autogroups";
    };
    corpStats = {
      enable = mkEnableOption "corpStats";
      module = atypes.mkModuleOption "allianceauth.corputils";
    };
    fleetActivityTracking = {
      enable = mkEnableOption "fleetActivityTracking";
      module = atypes.mkModuleOption "allianceauth.fleetactivitytracking";
    };
    hrApps = {
      enable = mkEnableOption "hrApps";
      module = atypes.mkModuleOption "allianceauth.hrapplications";
    };
    fleetOps = {
      enable = mkEnableOption "fleetOps";
      module = atypes.mkModuleOption "allianceauth.optimer";
    };
    permissionsAuditing = {
      enable = mkEnableOption "permissionsAuditing";
      module = atypes.mkModuleOption "allianceauth.permissions_tool";
    };
    shipReplacement = {
      enable = mkEnableOption "shipReplacement";
      module = atypes.mkModuleOption "allianceauth.srp";
    };
    structureTimers = {
      enable = mkEnableOption "structureTimers";
      module = atypes.mkModuleOption "allianceauth.timerboard";
    };
  };

  config.allauth.app.finalInstalledApps =
    let
      enabled = lib.filterAttrs (_: p: p.enable) cfg;
    in
    lib.mapAttrsToList (_: p: p.module) enabled;
}
