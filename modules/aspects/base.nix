{ aa, den, ... }:
let
  inherit (den.aspects.allauthConfig) user group;
in
{
  den.aspects.base.includes = [
    aa.network
    aa.ssh
    aa.user
  ];

  aa.network.nixos =
    {
      firewall,
      lib,
      ...
    }:
    {
      # Collect the disparate `firewall = { ports = [ 1234 ] }` declarations
      # from various aspects.
      networking.firewall.allowedTCPPorts = lib.concatMap (f: f.ports or [ ]) firewall;
    };

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

  aa.ssh.nixos = {
    # TODO: deployment/admin config
    services.openssh.enable = true;
  };
}
