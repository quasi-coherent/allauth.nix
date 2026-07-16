{
  inputs,
  self,
  ...
}:
let
  alib = import ./lib { inherit inputs; };
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
        ./options.nix
        ./modules/den.nix
        inputs.den.flakeModules.default
        (import ./allauth.nix {
          inherit (inputs) import-tree;
          sopsModule = inputs.sops.nixosModules.sops;
        })
        (import ./modules/venv.nix { inherit alib; })
      ];
    };
  };
}
