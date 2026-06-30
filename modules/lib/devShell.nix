{
  allauth-venv,
  age,
  fileset,
  mkShell,
  sops,
  uv,
}:
{
  packages ? [ ],
  ...
}@args:
mkShell (
  args
  // {
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
