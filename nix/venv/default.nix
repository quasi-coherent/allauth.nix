{ inputs, pkgs }:
let
  workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = ../../.;
  };
  venv = pkgs.callPackage ./package.nix {
    inherit (inputs) pyproject pyproject-build;
    inherit workspace;
  };
in
{
  inherit (venv) allauth-venv fileset;
}
