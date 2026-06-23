{ aa, ... }:
{
  den.aspects.allauthConfig.includes = [ aa.base ];

  aa.base.nixos =
    {
      firewall,
      lib,
      pkgs,
      ...
    }:
    {
      # Placeholder so that at least the resulting config can be evaluated.
      fileSystems."/" = {
        device = "/dev/null";
        fsType = "auto";
      };

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
}
