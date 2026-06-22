{
  inputs,
  self,
  ...
}:
{
  imports = [
    (inputs.den.namespace "aa" true)
    inputs.den.flakeModules.default
    ./devShell.nix
  ];

  flake = {
    lib = import ./lib { inherit inputs; };

    flakeModules = {
      default = self.flakeModules.allauth;

      allauth.imports = [
        ./options.nix
        ./allauth.nix
        ./aspects.nix
      ];
    };
  };
}
