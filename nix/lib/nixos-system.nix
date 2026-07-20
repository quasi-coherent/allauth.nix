{
  config,
  lib,
  ...
}:
let
  inherit (config) den;
in
{
  name,
  targetSystem ? config.allauth.targetSystem,
  specialArgs ? { },
  modules ? [ ],
}:
{
  ${name} = lib.nixosSystem {
    inherit specialArgs;
    modules = [ den.hosts.${targetSystem}.allauth.mainModule ] ++ modules;
  };
}
