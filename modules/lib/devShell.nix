{
  allauth-venv,
  age,
  fileset,
  mkShell,
  sops,
  stdenv,
  uv,
}:
{
  packages ? [ ],
  ...
}@args:
mkShell (
  args
  // {
    inherit (stdenv.hostPlatform) system;
    UV_NO_SYNC = "1";
    UV_PYTHON_DOWNLOADS = "never";
    UV_PYTHON = fileset.python.interpreter;

    packages = [
      allauth-venv
      age
      sops
      uv
    ]
    ++ packages;
  }
)
