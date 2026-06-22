{ aa, den, ... }:
let
  inherit (den.aspects.allauthConfig) user group;
in
{
  den.aspects.allauthConfig.includes = [ aa.user ];

  aa.user.nixos =
    { pkgs, ... }:
    {
      # Defines the user ${project}-admin
      users.users.${user} = {
        inherit group;
        shell = pkgs.nologin;
      };

      # Defines the group ${project}-admins
      users.groups.${group} = { };
    };
}
