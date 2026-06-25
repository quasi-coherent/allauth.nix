inputs:
inputs.flake-parts.lib.mkFlake { inherit inputs; } {
  systems = import inputs.systems;
  imports = [ ./modules/perSystem.nix ];

  flake = {
    nixosModules.default.imports = [ ./modules ];
  };
}
