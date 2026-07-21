{
  config,
  inputs,
  lib,
  self,
  ...
}:
let
  allauth-lib = import ./lib { inherit lib; };
in
{
  systems = [
    "aarch64-darwin"
    "x86_64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ];

  flake = {
    lib = {
      mkApp = allauth-lib.mkApp { inherit inputs; };
      denHost = allauth-lib.mkDenHost { inherit config; };
      nixosSystem = allauth-lib.mkNixosSystem { inherit config; };
    };

    flakeModules = {
      default = self.flakeModules.allauth;

      allauth.imports = [
        (import ./allauth.nix { inherit config inputs lib; })
      ];
    };
  };
}
