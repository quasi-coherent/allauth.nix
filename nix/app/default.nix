{ localFlake, mkPerSystemOption }:
{ config, lib, ... }:
let
  inherit (lib) mkOption types;

  cfg = config.allauth;

  aalib = import ./lib.nix {
    inherit (cfg) pyproject pyproject-build uv2nix;
    inherit lib;
  };
in
{
  options.perSystem = mkPerSystemOption (
    { pkgs, ... }:
    {
      options.allauth = {
        workspaceRoot = mkOption {
          type = types.path;
          default = ../../.;
          description = ''
            Path to a uv workspace that imports this project's `allauth` and
            installs `AllAuth` configuration.
          '';
        };
        uv2nix = mkOption {
          type = types.raw;
          default = localFlake.inputs.uv2nix;
          defaultText = lib.literalMD "`uv2nix` pinned by allauth.nix.";
          description = ''
            The `uv2nix` flake to use.

            Only applicable if `allauth.package` is a path.
          '';
        };
        pyproject = mkOption {
          type = types.raw;
          default = localFlake.inputs.pyproject;
          defaultText = lib.literalMD "`pyproject-nix/pyproject.nix` pinned by allauth.nix.";
          description = ''
            The `pyproject.nix` flake to use.

            Only applicable if `allauth.package` is a path.
          '';
        };
        pyproject-build = mkOption {
          type = types.raw;
          default = localFlake.inputs.pyproject-build;
          defaultText = lib.literalMD "`pyproject-nix/build-system-pkgs` pinned by allauth.nix.";
          description = ''
            The `pyproject-nix/build-system-pkgs` flake to use.

            Only applicable if `allauth.package` is a path.
          '';
        };
      };

      config =
        let
          venvPkgs = aalib.mkAllAuthPkgs {
            inherit pkgs;
            inherit (cfg) workspaceRoot;
          };
          inherit (venvPkgs) allauth-venv;
        in
        {
          _module.args = {
            aa-cli = pkgs.writeShellApplication {
              name = "aa";
              text = ''${allauth-venv}/bin/aa "$@"'';
            };
          };
        };
    }
  );
}
