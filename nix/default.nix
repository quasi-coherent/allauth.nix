{ inputs, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.partitions
    ./flakeModules.nix
  ];

  partitionedAttrs.devShells = "dev";
  partitionedAttrs.formatter = "dev";
  partitions.dev.extraInputsFlake = ../dev;
  partitions.dev.module = { inputs, ... }: {
    imports = [
      inputs.treefmt-nix.flakeModule
      ./allauth.nix
      ./dev.nix
    ];
  };
}
