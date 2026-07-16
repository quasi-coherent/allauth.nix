{ config, pkgs, ... }:
let
  name = config.allauth.project.name;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  den.hosts.${system}.allauth = {
    intoAttr = [
      "nixosConfigurations"
      name
    ];
  };
}
