{
  self,
  ...
}:
let
  alib = import ./lib;

  mkAllAuthVenv =
    { pkgs, ... }:
    alib.mkAllAuthVenv' {
      inherit (self) inputs;
      inherit pkgs;
    };

  mkAllAuthShell =
    { pkgs, ... }:
    alib.mkAllAuthShell' {
      inherit (self) inputs;
      inherit pkgs;
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
      venv = mkAllAuthVenv { inherit pkgs; };
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
