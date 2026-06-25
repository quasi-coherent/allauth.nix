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
  inputsFrom ? [ ],
  ...
}@args:
let
  cleanedArgs = removeAttrs args [
    "checks"
    "inputsFrom"
    "nativeBuildInputs"
  ];
in
mkShell (
  cleanedArgs
  // {
    inherit inputsFrom;

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
