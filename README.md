# allauth.nix

A WIP Nix flake providing a base NixOS configuration containing:
* An instance of the [Alliance Auth][django-app] Django application.
* Module options to configure and activate additional AA plugins/services.
* The infrastructure needed by the webapp.
* The supporting runtime for the webapp.
* Secrets management.

Future work:
* API for adding custom AA extensions.
* Tooling for deployment.

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

[django-app]: https://allianceauth.readthedocs.io/en/v5.1.4/features/overview.html
[`den`]: https://github.com/denful/den
[den-ns]: https://den.denful.dev/guides/namespaces/
