{ config, ... }:
let
  cfg = config.allauth;
  inherit (cfg) app targetSystem;
  inherit (app) projectName;
in
{
  den.aspects.${projectName}.includes = [
    cfg.den.aspects.allauth
  ];

  den.hosts.${targetSystem}.${projectName} = { };
}
