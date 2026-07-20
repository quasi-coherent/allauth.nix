{
  inputs,
  lib,
  ...
}:
let
  mkApp = import ./appPkgs.nix { inherit inputs lib; };
  allauth-lib = {
    inherit mkApp;
    mkDenHost = ./den-host.nix;
    mkNixosSystem = ./nixos-system.nix;
  };
in
allauth-lib
