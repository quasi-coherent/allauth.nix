{
  callPackage,
  lib,
  libmysqlclient,
  pkg-config,
  pyproject,
  pyproject-build,
  python314,
  openssl,
  workspace,
  zlib,
}:
let
  builderOverlay = pyproject-build.overlays.default;

  # Avoid building binaries.
  wheels = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };

  # Packages that are missing setuptools need to be patched.
  needsSetuptools = [
    "celery-once"
    "slixmpp"
    "openfire-restapi"
    "pydiscourse"
    "django-sri"
    "telnetlib3"
    "ua-parser"
    "user-agents"
  ];
  pyprojectOverrides =
    final: prev:
    (lib.genAttrs needsSetuptools (
      name:
      prev.${name}.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.setuptools ];
      })
    ))
    // {
      mysqlclient = prev.mysqlclient.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
          final.setuptools
          pkg-config
        ];
        # Non-py dylibs
        buildInputs = (old.buildInputs or [ ]) ++ [
          libmysqlclient
          openssl
          zlib
        ];
      });
    };
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
  inherit fileset allauth-venv;
}
