{
  allauth-venv,
  age,
  fileset,
  mkShell,
  sops,
  uv,
}:
{
  checks ? { },
  inputsFrom ? [ ],
  packages ? [ ],
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
    inputsFrom = builtins.attrValues checks ++ inputsFrom;

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
