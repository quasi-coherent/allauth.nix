{
  lib,
  inputs,
  ...
}:
pkgs:
{
  workspaceRoot,
  python ? pkgs.python314,
  extraOverlays ? [ ],
}:
let
  inherit (inputs)
    pyproject
    pyproject-build
    uv2nix
    ;

  workspace = uv2nix.lib.workspace.loadWorkspace {
    inherit workspaceRoot;
  };
  builderOverlay = pyproject-build.overlays.default;

  # Prefer downloading binary wheels.  It's more likely to Just Work (TM).
  wheels = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };

  # The allianceauth project has a number of dependencies that are missing
  # things required to build from source, so we need an overlay that patches
  # these issues.
  allauthPatchOverlay = pkgs.callPackage ./overlay.nix { };
  pypkgs = pkgs.callPackage pyproject.build.packages { inherit python; };

  fileset = pypkgs.overrideScope (
    lib.composeManyExtensions (
      [
        builderOverlay
        wheels
        allauthPatchOverlay
      ]
      ++ extraOverlays
    )
  );

  # The main venv for deployment.
  allauth-venv = fileset.mkVirtualEnv "allauth-venv" workspace.deps.default;

  # Shell script wrapper of the venv's CLI command.
  allauth-bin = pkgs.writeShellApplication {
    name = "allauth-bin";
    text = ''exec ${allauth-venv}/bin/aa "$@"'';
  };

  allauthShell =
    {
      checks ? { },
      inputsFrom ? [ ],
      packages ? [ ],
      ...
    }@args:
    let
      cleanArgs = removeAttrs args [
        "checks"
        "inputsFrom"
        "nativeBuildInputs"
        "shellHook"
      ];
      # Local packages are usually installed in "editable mode" that allows scripts
      # and such to be installed as pointers to the source tree, obviating the need
      # to rebuild on changes.  But uv2nix makes us create a whole different overlay
      # and package set to do this.
      # The editable root must be the live checkout, not the store copy of
      # workspaceRoot, so it is resolved at shell entry via $REPO_ROOT.
      editableOverlay = workspace.mkEditablePyprojectOverlay {
        root = "$REPO_ROOT";
      };
      editableFileset = fileset.overrideScope editableOverlay;
      allauth-devenv = editableFileset.mkVirtualEnv "allauth-devenv" workspace.deps.all;
    in
    pkgs.mkShell (
      cleanArgs
      // {
        inputsFrom = builtins.attrValues checks ++ inputsFrom;
        shellHook = ''
          export REPO_ROOT=$(git rev-parse --show-toplevel)
          ${args.shellHook or ""}
        '';
        UV_NO_SYNC = "1";
        UV_PYTHON_DOWNLOADS = "never";
        UV_PYTHON = editableFileset.python.interpreter;
        packages = [
          allauth-devenv
          pkgs.uv
          pkgs.ruff
        ]
        ++ packages;
      }
    );
in
{
  inherit
    allauth-bin
    allauth-venv
    fileset
    allauthShell
    ;
}
