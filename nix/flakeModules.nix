{ self, ... }:
{
  nixosModules = {
    default = self.nixosModules.allauth;
    allauth.imports = [ ../modules ];
  };
}
