{ inputs, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.partitions
    ./flake-parts.nix
  ];

  partitionedAttrs.checks = "dev";
  partitionedAttrs.devShells = "dev";
  partitionedAttrs.formatter = "dev";
  partitions.dev.extraInputsFlake = ../dev;
  partitions.dev.module = { inputs, ... }: {
    imports = [
      inputs.treefmt-nix.flakeModule
      inputs.den.flakeModules.default
      ./aspects
      ./perSystem.nix
      (inputs.den.namespace "aa" true)
    ];
  };
}
