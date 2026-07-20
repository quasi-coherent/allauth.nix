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
  includes ? [ ],
  userAspects ? { },
}:
{
  ${targetSystem}.${name} = {
    includes = [ den.aspects.allauth ] ++ includes;
    users = (lib.mkIf userAspects != { }) userAspects;
  };
}
