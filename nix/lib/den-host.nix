{
  config,
  lib,
  ...
}:
let
  inherit (config) den;
in
{
  includes ? [ ],
  userAspects ? { },
}:
{
  includes = [ den.aspects.allauth ] ++ includes;
  users = (lib.mkIf userAspects != { }) userAspects;
}
