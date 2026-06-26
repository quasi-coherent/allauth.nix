{ config, ... }:
let
  inherit (config) allauth den;
  inherit (allauth) app targetSystem;
  inherit (app) projectName;
in
{
  den.aspects.${projectName}.includes = [
    den.aspects.allauth
  ];

  den.hosts.${targetSystem}.${projectName} = { };
}
