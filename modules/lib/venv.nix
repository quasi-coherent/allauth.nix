{
  callPackage,
  lib,
  pyproject,
  pyproject-build,
  python314,
  workspace,
}:
let
  builderOverlay = pyproject-build.overlays.default;

  # Download binary wheels whenever possible.
  wheels = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };

  # Build fix-ups for allauth's dependency closure.
  pyprojectOverrides = callPackage ./overrides.nix { };

  pyProject = callPackage pyproject.build.packages {
    python = python314;
  };
  fileset = pyProject.overrideScope (
    lib.composeManyExtensions [
      builderOverlay
      wheels
      pyprojectOverrides
    ]
  );
  allauth-venv = fileset.mkVirtualEnv "allauth-venv" workspace.deps.default;
in
{
  inherit
    fileset
    allauth-venv
    pyprojectOverrides
    ;
  # The bare project package (no virtualenv) to layer over from downstream
  # consumers of this flake.
  allauth = fileset.allauth;
}
