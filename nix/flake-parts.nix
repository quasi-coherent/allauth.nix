{
  flake-parts-lib,
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
        pyproject ? self.inputs.pyproject,
        pyproject-build ? self.inputs.pyproject-build,
        uv2nix ? self.inputs.uv2nix,
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
        (importApply ./app {
          inherit mkPerSystemOption;
          localFlake = self;
        })
        (importApply ./host.nix self)
      ];
    };
  };
}
