{ den, ... }:
{
  den = {
    default = {
      includes = [
        # auto-provision name/homeDir for a user defined on a host.
        den.batteries.define-user
        den.batteries.hostname
        den.batteries.inputs'
        den.batteries.self'
      ];

      nixos.system.stateVersion = "26.05";
    };

    quirks = {
      # firewall.ports: list of TCP ports to allow connections on.
      firewall.description = "Firewall port declaration.";
    };
  };
}
