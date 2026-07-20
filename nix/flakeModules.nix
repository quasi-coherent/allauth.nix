{
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
    };

    flakeModules = {
      default = self.flakeModules.allauth;

      allauth =
        { config, lib, ... }:
        {
          imports = [
            (import ./allauth.nix { inherit config inputs lib; })
          ];

          build = {
            denHost = allauth-lib.mkDenHost { inherit config; };
            nixosSystem = allauth-lib.mkNixosSystem { inherit config; };
          };
        };
    };
  };
}
