{ inputs }:
let
  overrides = pkgs: pkgs.callPackage ./overrides.nix { };

  mkAllAuthVenv =
    {
      pkgs,
      workspaceRoot,
    }:
    let
      workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
        inherit workspaceRoot;
      };
      venv = pkgs.callPackage ./venv.nix {
        inherit (inputs) pyproject pyproject-build;
        inherit workspace;
      };
    in
    {
      inherit (venv)
        allauth
        allauth-venv
        fileset
        pyprojectOverrides
        ;
    };

  mkAllAuthShell =
    {
      pkgs,
      workspaceRoot,
    }:
    let
      venv = mkAllAuthVenv {
        inherit
          pkgs
          workspaceRoot
          ;
      };
    in
    pkgs.callPackage ./devShell.nix { inherit (venv) allauth-venv fileset; };
in
{
  inherit overrides mkAllAuthShell mkAllAuthVenv;
}
