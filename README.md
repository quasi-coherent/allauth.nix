# allauth.nix

Flake to build a NixOS system for hosting [Alliance Auth][django-app].  High level features:

* Provides an app configuration class to import into your own project and feed back into the NixOS
  system with module options.  This:
  - Handles packaging, installing, startup, and maintenance and admin tasks.
  - Replaces `settings/local.py` so you don't manage configuration by hand on a deployed instance.
  - Exposes a simplified plugin/service interface to customize arbitrarily, either by adding third
    party community app, or by referencing your own project.
* Provides all the infrastructure needed: background daemons for task scheduling, database and cache
  setup, user and group management, networking components, and the actual webserver with proxy.
  - Module options expose the full NixOS options tree so you can add whatever you want to this.
* Manages secret values with [sops-nix](https://github.com/Mic92/sops-nix).
  - You only provide the key in a local `secrets.yaml` file.  Building the system handles
    constructing the proper environment and secrets stay encrypted always.

[django-app]: https://allianceauth.readthedocs.io/en/v5.1.4/index.html
