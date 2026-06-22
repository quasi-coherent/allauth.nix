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
      # This is a placeholder `nixos.fileSystems`.  Without it, the flake will
      # fail to evaluate.  The resulting configuration is not usable, so a user
      # must provide overriding configuration.
      boot.loader.grub.enable = false;
      fileSystems."/".device = "/dev/null";
      fileSystems."/".fsType = "auto";

      environment.systemPackages = with pkgs; [
        emacs30
        fd
        git
        jq
        nh
        ripgrep
        sd
      ];

      networking.firewall.allowedTCPPorts = lib.concatMap (f: f.ports or [ ]) firewall;
    };
}
