{ config, lib, ... }:
let
  inherit (lib) mkEnableOption;
  inherit (import ../lib { inherit lib; }) mkModuleOption;
  cfg = config.allauth.plugins;
in
{
  options.allauth.plugins = {
    autoGroups = {
      enable = mkEnableOption "autoGroups";
      module = mkModuleOption "allianceauth.eveonline.autogroups";
    };
    corpStats = {
      enable = mkEnableOption "corpStats";
      module = mkModuleOption "allianceauth.corputils";
    };
    fleetActivityTracking = {
      enable = mkEnableOption "fleetActivityTracking";
      module = mkModuleOption "allianceauth.fleetactivitytracking";
    };
    hrApps = {
      enable = mkEnableOption "hrApps";
      module = mkModuleOption "allianceauth.hrapplications";
    };
    fleetOps = {
      enable = mkEnableOption "fleetOps";
      module = mkModuleOption "allianceauth.optimer";
    };
    permissionsAuditing = {
      enable = mkEnableOption "permissionsAuditing";
      module = mkModuleOption "allianceauth.permissions_tool";
    };
    shipReplacement = {
      enable = mkEnableOption "shipReplacement";
      module = mkModuleOption "allianceauth.srp";
    };
    structureTimers = {
      enable = mkEnableOption "structureTimers";
      module = mkModuleOption "allianceauth.timerboard";
    };
  };

  config.allauth.app.finalInstalledApps =
    let
      enabled = lib.filterAttrs (_: p: p.enable) cfg;
    in
    lib.mapAttrsToList (_: p: p.module) enabled;
}
