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
        package = mkOption {
          type = with types; either package path;
          default = ../../.;
          description = ''
            Either a package derivation or path to a uv workspace.

            If a package is provided, then it must expose the binary script `aa`
            that is exported as `allauth.runner.aa` by the `allauth` dependency.

            In either case, the configured `AllAuth` instance must be installed
            in the same Python module as what is provided in this flake module's
            option `allauth.settingsModule`.
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
          allauth-venv =
            if builtins.isPath cfg.package then
              cfg.package
            else
              let
                venvPkgs = aalib.mkAllAuthPkgs {
                  inherit pkgs;
                  workspaceRoot = cfg.package;
                };
                inherit (venvPkgs) allauth-venv;
              in
              allauth-venv;
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
