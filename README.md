# allauth.nix

Flake to build a NixOS system for hosting [Alliance Auth](django-app).

Has:
* A running AA webapp.
* Module options to augment/customize the webapp.
* Infrastructure needed by the webapp.
* Runtime for django-admin and starting services, including the webapp.
* Secrets management for the webapp.

<!-- ## Usage -->

<!-- ```nix -->
<!-- inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable"; -->
<!-- inputs.allauth-nix.url = "github:quasi-coherent/allauth.nix"; -->
<!-- inputs.allauth-nix.inputs.nixpkgs.follows = "nixpkgs"; -->
<!-- ``` -->

<!-- This flake builds system configuration using the [`den`] framework, so it is -->
<!-- helpful to be somewhat familiar with the terminology before reading the rest of -->
<!-- of this section.  Consuming this API also requires a basic familiarity with the -->
<!-- library. -->

<!-- ### Example -->

<!-- To use, import the main module and provide the module options `allauth`: -->

<!-- ```nix -->
<!-- imports = [ inputs.allauth-nix.flakeModules.default ]; -->

<!-- allauth = { -->
<!--   projectName = "mycool-app"; -->
<!--   siteName = "My Cool App"; -->
<!--   siteUrl = "https://auth.mycoolapp.space"; -->
<!--   # More on this below: -->
<!--   sopsFile = ./secrets/secrets.yaml; -->
<!--   addOns = { -->
<!--     # Add stock AA plugin apps: -->
<!--     shipReplacement.enable = true; -->
<!--     structureTimers.enable = true; -->
<!--     # Add supported AA services: -->
<!--     discord = { -->
<!--       enable = true; -->
<!--       syncNames = true; -->
<!--       tasks = [ -->
<!--         { taskType = "update_all"; cronExpr = "0 */12 * * *"; } -->
<!--       ]; -->
<!--     }; -->
<!--   }; -->
<!-- }; -->
<!-- ``` -->

## Customizing the AA runtime

This flake has a package output providing the Python package `allauth` as a
`pyproject` fileset.  This allows a user to import it and layer additional
functionality within the virtualenv that supplies the app runtime.

Relevant outputs are:

* `packages.<system>.allauth`: Thin AA wrapper package.  This package collects
  environment variables that otherwise would need to be written directly into
  the Django settings/local.py file.  `options.allauth.project.package` defaults
  to the virtualenv built from this minimum package.
* `overlays.default` — a `pyproject.nix` fileset overlay patching some of the
  `allauth` dependencies that are lacking setuptools or other build requirements.

Add the package `allauth` as a dependency, sourced via `[tool.uv.sources]`, and
use as in

```nix
pythonSet = pythonBase.overrideScope (lib.composeManyExtensions [
  pyproject-build-systems.overlays.wheel  (workspace.mkPyprojectOverlay { sourcePreference = "wheel"; })
  (allauth.overlays.default pkgs)
]);
venv = pythonSet.mkVirtualEnv "my-allauth-venv" workspace.deps.default;
```

where `workspace` is a suitable `uv2nix` "workspace" loaded from the local source.

This `venv` can be handed to the module options `allauth.app.package`, which only
expects a virtualenv that preserves the validity of the CLI subcommands needed at
runtime, defined [here](./modules/lib/cli.nix).

[django-app]: https://allianceauth.readthedocs.io/en/v5.1.4/features/overview.html
