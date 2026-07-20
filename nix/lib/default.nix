{
  lib,
  ...
}:
let
  mkApp = { inputs }: import ./appPkgs.nix { inherit inputs lib; };
  mkDenHost = { config }: import ./den-host.nix { inherit config lib; };
  mkNixosSystem = { config }: import ./nixos-system.nix { inherit config lib; };
in
{
  inherit mkApp mkDenHost mkNixosSystem;
}
