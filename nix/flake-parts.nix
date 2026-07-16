{
  inputs,
  self,
  ...
}:
let
  alib = import ./lib { inherit inputs; };

  allauthModule = {
    imports = [
      (import ./allauth.nix { inherit inputs; })
      (import ./modules/venv.nix { inherit alib; })
      ./options.nix
      inputs.den.flakeModules.default
    ];
  };
in
{
  systems = [
    "aarch64-darwin"
    "x86_64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ];

  flake = {
    lib = {
      inherit (alib)
        mkAllAuthVenv
        mkAllAuthShell
        ;
    };

    overlays.default = alib.overrides;

    flakeModules = {
      default = self.flakeModules.den;
      den.imports = [
        ./modules/den.nix
        allauthModule
      ];
    };
  };
}
