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
      packages = { inherit (venv) allauth-venv; };
    };

  flake = {
    lib = {
      inherit (alib) mkAllAuthCli;
      inherit mkAllAuthVenv mkAllAuthShell;
    };

    flakeModules = {
      default = self.nixosModules.allauth;
      allauth.imports = [
        ./allauth.nix
        ./host.nix
      ];
    };
  };
}
