{ den, inputs, ... }:
{
  imports = [
    (inputs.den.namespace "aa" true)
    ./base.nix
    ./secrets.nix
    ./storage.nix
    ./user.nix
    ./web.nix
  ];

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
      # projectValues.env: variables that can be statically defined without
      # sops activation.
      projectValues.description = "Non-secret values needed by the environment.";

      # projectSecretValues.envKeyMap: mapping env vars to keys of the sops file.
      # projectSecretValues.sopsFile: path to the sops secret file.
      projectSecretValues.description = "Secrets needed by this AA project's environment.";

      # firewall.ports: list of TCP ports to allow connections on.
      firewall.description = "Firewall port declaration.";
    };
  };
}
