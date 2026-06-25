{ inputs, ... }:
{
  imports = [
    (inputs.den.namespace "aa" true)
    ./app.nix
    ./base.nix
    ./secrets.nix
    ./storage.nix
    ./user.nix
  ];
}
