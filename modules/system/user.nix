{ den, ... }:
let
  inherit (den.aspects.allauthConfig) user group;
in
{
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
