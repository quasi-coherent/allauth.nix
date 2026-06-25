{
  aa.base.nixos =
    {
      firewall,
      lib,
      pkgs,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        emacs30
        fd
        git
        jq
        nh
        ripgrep
        sd
      ];

      # Collect the disparate `firewall = { ports = [ 1234 ] }` declarations
      # from various aspects.
      networking.firewall.allowedTCPPorts = lib.concatMap (f: f.ports or [ ]) firewall;
    };

  # Placeholder root directory mountpoint so that the resulting config at least
  # evaluates.  Users will want to change this or not include it.
  aa.dummyRootMount.nixos = {
    fileSystems."/" = {
      device = "/dev/null";
      fsType = "auto";
    };
  };
}
