{
  lib,
  libmysqlclient,
  pkg-config,
  openssl,
  zlib,
}:
let
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
in
final: prev:
(lib.genAttrs needsSetuptools (
  name:
  prev.${name}.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.setuptools ];
  })
))
// {
  # The editable root package is built with hatchling; uv2nix doesn't inject
  # the build backend automatically, so provide it explicitly.
  allauth = prev.allauth.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.hatchling ];
  });

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
}
