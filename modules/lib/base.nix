{ lib, ... }:
{
  den.aspects.filesystem.nixos = {
    # Without this the config fails to evaluate.
    fileSystems = lib.mkDefault {
      "/" = {
        device = "none";
        fsType = "tmpfs";
      };
    };
  };

  den.aspects.global.nixos = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.age
      pkgs.emacs30
      pkgs.fd
      pkgs.git
      pkgs.jq
      pkgs.ripgrep
      pkgs.sd
      pkgs.sops
      pkgs.openssh
    ];
  };

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
    { config, pkgs, ... }:
    let
      conf = config.allauthConf;
    in
    {
      # Defines the user ${project}-admin
      users.users.${conf.user} = {
        inherit (conf) group;
        isSystemUser = true;
        shell = "${pkgs.shadow}/bin/nologin";
      };

      # Defines the group ${project}-admins
      users.groups.${conf.group} = { };
    };

  den.aspects.ssh.nixos = {
    # TODO: config.
    services.openssh.enable = true;
  };
}
