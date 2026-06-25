{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
    ./devShells.nix
    ./packages
    ./flakeModules.nix
  ];

  perSystem.treefmt = {
    projectRootFile = ".git/config";
    programs = {
      nixfmt.enable = true;
      deadnix.enable = true;
      ruff-check.enable = true;
      ruff-format.enable = true;
      typos.enable = true;
    };
    settings.excludes = [
      ".direnv/*"
    ];
  };
}
