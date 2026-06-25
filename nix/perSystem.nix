{
  inputs,
  lib,
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
      venv = import ./venv { inherit inputs pkgs; };
      inherit (venv) allauth-venv fileset;

      fmtt = pkgs.writeShellApplication {
        name = "fmtt";
        text = ''${lib.getExe self'.formatter} "$@"'';
      };
    in
    {
      packages.allauth-venv = allauth-venv;

      devShells.default = pkgs.mkShell {
        # Prevents uv from managing virtual environments or downloading managed
        # interpreters.
        UV_NO_SYNC = "1";
        UV_PYTHON_DOWNLOADS = "never";
        # Use this interpreter path instead for all uv operations.
        UV_PYTHON = fileset.python.interpreter;
        # Having PYTHONPATH available can allow undeclared dependencies to
        # become available to the interpreter, which has unpredictable side
        # effects.
        shellHook = "unset PYTHONPATH";

        packages = [
          allauth-venv
          fmtt
          pkgs.age
          pkgs.git
          pkgs.nh
          pkgs.nixd
          pkgs.python314Packages.ruff
          pkgs.python314Packages.python-lsp-ruff
          pkgs.sops
          pkgs.uv
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
  imports = [ inputs.treefmt-nix.flakeModule ];
}
