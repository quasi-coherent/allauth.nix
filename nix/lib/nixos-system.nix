{
  config,
  lib,
  ...
}:
let
  inherit (config) den;
in
{
  targetSystem ? "x86_64-linux",
  specialArgs ? { },
  modules ? [ ],
}:
lib.nixosSystem {
  inherit specialArgs;
  modules = [ den.hosts.${targetSystem}.allauth.mainModule ] ++ modules;
}
