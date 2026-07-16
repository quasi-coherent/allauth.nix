{ lib, ... }:
{
  aa.filesystem.nixos = {
    # Without this the config fails to evaluate.
    fileSystems = lib.mkDefault {
      "/" = {
        device = "none";
        fsType = "tmpfs";
      };
    };
  };

  aa.systemEnv.nixos = { pkgs, ... }: {
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
    { config, pkgs, ... }:
    {
      # Defines the user ${project}-admin
      users.users.${config.user} = {
        inherit (config) group;
        isSystemUser = true;
        shell = "${pkgs.shadow}/bin/nologin";
      };

      # Defines the group ${project}-admins
      users.groups.${config.group} = { };
    };

  aa.ssh.nixos = {
    # TODO: config.
    services.openssh.enable = true;
  };
}
