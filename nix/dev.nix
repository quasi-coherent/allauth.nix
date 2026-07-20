{ self, ... }:
{
  perSystem =
    {
      lib,
      pkgs,
      self',
      ...
    }:
    let
      appPkgs = self.lib.mkApp pkgs { workspaceRoot = ../.; };

      fmtt = pkgs.writeShellApplication {
        name = "fmtt";
        text = ''${lib.getExe self'.formatter} "$@"'';
      };

      pypkgs = pkgs.python314Packages;
    in
    {
      devShells.default = appPkgs.allauthShell {
        shellHook = "unset PYTHONPATH";
        packages = [
          fmtt
          pkgs.nh
          pkgs.nixd
          pypkgs.uv
          pypkgs.ruff
          pypkgs.python-lsp-ruff
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
}
