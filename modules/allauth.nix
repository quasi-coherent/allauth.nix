{ den, ... }:
{
  den.aspects.allauth.includes = [ den.aspects.allauthConfig ];
  den.schema.flake-system.includes = [ den.aspects.allauth ];
}
