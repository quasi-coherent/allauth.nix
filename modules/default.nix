{ inputs, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.partitions
    ./flakeModule.nix
  ];

  perSystem =
    { pkgs, ... }:
    let
      venv = import ./venv { inherit inputs pkgs; };
    in
    {
      packages = { inherit (venv) allauth-venv; };
    };

  partitionedAttrs.checks = "dev";
  partitionedAttrs.devShells = "dev";
  partitionedAttrs.formatter = "dev";
  partitions.dev.extraInputsFlake = ../dev;
  partitions.dev.module = { inputs, ... }: {
    imports = [
      inputs.treefmt-nix.flakeModule
      ./perSystem.nix
    ];
  };
}
