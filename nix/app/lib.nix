{
  pyproject,
  pyproject-build,
  uv2nix,
}:
let
  mkAllAuthPkgs =
    {
      pkgs,
      workspaceRoot,
      extraOverlays ? [ ],
    }:
    let
      workspace = uv2nix.lib.workspace.loadWorkspace {
        inherit workspaceRoot;
      };
      venv = pkgs.callPackage ./venv.nix {
        inherit
          pyproject
          pyproject-build
          workspace
          extraOverlays
          ;
      };
    in
    {
      inherit (venv)
        allauth-venv
        fileset
        ;
    };

  mkAllAuthShell =
    {
      pkgs,
      workspaceRoot,
      extraOverlays ? [ ],
    }:
    let
      venvPkgs = mkAllAuthPkgs { inherit pkgs workspaceRoot extraOverlays; };
      inherit (venvPkgs) allauth-venv fileset;
    in
    pkgs.callPackage ./shell.nix {
      inherit allauth-venv fileset;
    };
in
{
  inherit mkAllAuthPkgs mkAllAuthShell;
}
