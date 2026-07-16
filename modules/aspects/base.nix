{ den, ... }:
let
  inherit (den.aspects.allauthConfig) user group;
in
{
  den.aspects.base.includes = [
    den.aspects.filesystem
    den.aspects.network
    den.aspects.ssh
    den.aspects.user
  ];

  den.aspects.network.nixos =
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

  den.aspects.user.nixos =
    { pkgs, ... }:
    {
      # Defines the user ${project}-admin
      users.users.${user} = {
        inherit group;
        isSystemUser = true;
        shell = "${pkgs.shadow}/bin/nologin";
      };

      # Defines the group ${project}-admins
      users.groups.${group} = { };
    };

  den.aspects.ssh.nixos = {
    # TODO: deployment/admin config.
    services.openssh.enable = true;
  };
}
