{ alib }:
{ config, pkgs, ... }:
let
  cfg = config.allauth.project;
  venv = alib.mkAllAuthVenv {
    inherit pkgs;
    workspaceRoot = cfg.root;
  };
  inherit (venv) allauth-venv;
in
{
  packages = {
    "${cfg.name}-venv" = allauth-venv;
  };
}
