{ inputs, ... }:
let
  mkAllAuthVenv =
    { pkgs, ... }:
    let
      workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
        workspaceRoot = ../../.;
      };
      venv = pkgs.callPackage ./venv.nix {
        inherit (inputs) pyproject pyproject-build;
        inherit workspace;
      };
    in
    {
      inherit (venv) fileset allauth-venv;
    };

  perSystem =
    { pkgs, ... }:
    {
      packages = {
        inherit (mkAllAuthVenv { inherit pkgs; }) allauth-venv;
      };
    };
in
{
  inherit perSystem;
}
