{
  self,
  ...
}:
{
  systems = [
    "aarch64-darwin"
    "x86_64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ];

  flake = {
    lib =
      let
        alib = import ./lib;
      in
      {
        inherit (alib) mkAllAuthCli;

        mkAllAuthVenv =
          { pkgs, ... }:
          alib.mkAllAuthVenv' {
            inherit (self) inputs;
            inherit pkgs;
          };
      };

    nixosModules = {
      default = self.nixosModules.allauth;
      allauth.imports = [
        ./allauth.nix
        ./host.nix
      ];
    };
  };
}
