# allauth.nix

Flake to build a NixOS system for hosting [Alliance Auth](django-app).

Has:
* A running AA webapp.
* Module options to augment/customize the webapp.
* Infrastructure needed by the webapp.
* Runtime for django-admin and starting services, including the webapp.
* Secrets management for the webapp.

[django-app]: https://allianceauth.readthedocs.io/en/v5.1.4/features/overview.html
