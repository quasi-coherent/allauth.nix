{ lib, ... }:
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
  mysqlclient = prev.mysqlclient.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
      final.setuptools
      final.pkg-config
    ];
    # Non-py dylibs
    buildInputs = (old.buildInputs or [ ]) ++ [
      final.libmysqlclient
      final.openssl
      final.zlib
    ];
  });
}
