{
  lib,
  self,
  ...
}:
let
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    let
      fmtt = pkgs.writeShellApplication {
        name = "fmtt";
        text = ''${lib.getExe self'.formatter} "$@"'';
      };

      mkAllAuthShell = self.lib.mkAllAuthShell { inherit pkgs; };
    in
    {
      devShells.default = mkAllAuthShell {
        shellHook = "unset PYTHONPATH";

        packages = [
          fmtt
          pkgs.git
          pkgs.nh
          pkgs.nixd
          pkgs.python314Packages.ruff
          pkgs.python314Packages.python-lsp-ruff
        ];
      };

      treefmt = {
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
    };
in
{
  inherit perSystem;
}
