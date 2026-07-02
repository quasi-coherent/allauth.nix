let
  overrides = pkgs: pkgs.callPackage ./overrides.nix { };

  types = { lib }: {
    mkModuleOption =
      pyMod:
      lib.mkOption {
        type = lib.types.str;
        default = pyMod;
        description = "AA module path ${pyMod}.";
        readOnly = true;
      };
  };

  mkAllAuthVenv' =
    {
      inputs,
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

  mkAllAuthShell' =
    {
      pkgs,
      allauth-venv,
      fileset,
    }:
    pkgs.callPackage ./devShell.nix { inherit allauth-venv fileset; };
in
{
  inherit
    mkAllAuthVenv'
    mkAllAuthShell'
    overrides
    types
    ;
}
