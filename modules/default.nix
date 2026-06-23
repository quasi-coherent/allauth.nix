{
  inputs,
  self,
  ...
}:
{
  imports = [
    (inputs.den.namespace "aa" true)
    inputs.den.flakeModules.default
    ./aspects
    ./devShells.nix
  ];

  flake = {
    lib = import ./lib { inherit inputs; };

    flakeModules = {
      default = self.flakeModules.allauth;

      allauth.imports = [
        ./allauth.nix
        ./aspects
      ];
    };
  };
}
