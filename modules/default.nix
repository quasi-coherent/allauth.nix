{
  inputs,
  ...
}:
{
  imports = [
    (inputs.den.namespace "aa" true)
    inputs.den.flakeModules.default

    ./allauth.nix
    ./den.nix
    ./options.nix
    ./system/app.nix
    ./system/base.nix
    ./system/secrets.nix
    ./system/storage.nix
    ./system/user.nix
  ];
}
