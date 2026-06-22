{ inputs, ... }:
let
  mkAllAuthVenv =
    { pkgs }:
    let
      workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
        workspaceRoot = ../../.;
      };
      venv = pkgs.callPackage ./venv.nix {
        inherit workspace;
        inherit (inputs) pyproject pyproject-build;
      };
    in
    {
      inherit (venv) fileset allauth-venv;
    };

  mkAllAuthCli =
    {
      pkgs,
      projectDir,
      projectName,
    }:
    let
      inherit (mkAllAuthVenv { inherit pkgs; }) allauth-venv;
    in
    pkgs.callPackage ./cli.nix { inherit allauth-venv projectDir projectName; };
in
{
  inherit
    mkAllAuthCli
    mkAllAuthVenv
    ;
}
