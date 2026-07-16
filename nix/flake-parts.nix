{
  flake-parts-lib,
  inputs,
  lib,
  self,
  ...
}:
let
  inherit (flake-parts-lib) importApply mkPerSystemOption;
in
{
  systems = [
    "aarch64-darwin"
    "x86_64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ];

  flake = {
    lib =
      {
        pyproject ? inputs.pyproject,
        pyproject-build ? inputs.pyproject-build,
        uv2nix ? inputs.uv2nix,
      }:
      import ./app/lib.nix {
        inherit
          pyproject
          pyproject-build
          uv2nix
          ;
      };

    overlays.default = import ./app/overlay.nix { inherit lib; };

    flakeModules = {
      default.imports = [
        ./options.nix
        ./allauth.nix
        (importApply ./app {
          inherit mkPerSystemOption;
          localFlake = self;
        })
        (importApply ./host.nix { localFlake = self; })
      ];
    };
  };
}
