{
  self,
  ...
}:
let
  alib = import ./lib;

  mkAllAuthVenv =
    {
      pkgs,
      workspaceRoot,
    }:
    alib.mkAllAuthVenv' {
      inherit (self) inputs;
      inherit pkgs workspaceRoot;
    };

  mkAllAuthShell =
    {
      pkgs,
      allauth-venv,
      fileset,
    }:
    alib.mkAllAuthShell' {
      inherit pkgs allauth-venv fileset;
    };
in
{
  systems = [
    "aarch64-darwin"
    "x86_64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ];

  perSystem =
    { pkgs, ... }:
    let
      venv = mkAllAuthVenv {
        inherit pkgs;
        workspaceRoot = ../.;
      };
    in
    {
      packages = { inherit (venv) allauth; };
    };

  flake = {
    lib = {
      inherit (alib) mkAllAuthCli overrides;
      inherit mkAllAuthVenv mkAllAuthShell;
    };

    overlays.default = alib.overrides;

    flakeModules = {
      default = self.flakeModules.allauth;
      allauth.imports = [ ./allauth.nix ];
    };
  };
}
