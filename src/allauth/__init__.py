import os

from dataclasses import dataclass
from typing import Any, Self

from .addons import AppPlugin
from .defaults import _var_defaults, _CELERY_CONF_DEFAULTS
from .runner import Runner

# Import for side effect.
#
# This is because AA define their tasks with `@shared_task`, which binds to
# whatever Celery app is current _at call time_.  So importing it here ensures
# the app exists in every process, as downstream will have a top level that does
# `from allauth import AllianceAuthApp`.
from .celery import app as celery_app  # noqa: F401

__all__ = [
    "AllAuth",
    "AppPlugin",
    "SiteConfig",
    "Runner",
]


def _apply_runtime_env(ns: dict[str, Any]) -> list[str]:
    exported: list[str] = []

    static_root = os.environ.get("AA_STATIC_ROOT")
    if static_root is not None:
        ns["STATIC_ROOT"] = static_root
        ns["STATICFILES_DIRS"] = []
        exported += ["STATIC_ROOT", "STATICFILES_DIRS"]

    # The venv is in the nix store, so we can't write log files there, which is
    # the default.  Need to re-point all the logger handles accordingly.
    log_dir = os.environ.get("AA_LOG_DIR")
    if log_dir is not None:
        for handler in ns.get("LOGGING", {}).get("handlers", {}).values():
            if "filename" in handler:
                handler["filename"] = os.path.join(
                    log_dir, os.path.basename(handler["filename"])
                )

    # The user authenticates as a unix user who has rw on this socket, so there
    # is no password.
    db_name = os.environ.get("AA_DB_NAME")
    if db_name is not None:
        ns.setdefault("DATABASES", {})["default"] = {
            "ENGINE": "django.db.backends.mysql",
            "NAME": db_name,
            "USER": os.environ["AA_DB_USER"],
            "OPTIONS": {
                "unix_socket": os.environ.get(
                    "AA_DB_SOCKET", "/run/mysqld/mysqld.sock"
                ),
                "charset": "utf8mb4",
            },
        }
        exported.append("DATABASES")

    return exported


@dataclass
class SiteConfig:
    """
    Basic required project configuration.

    :site_name: Name displayed in page titles and site header.
    :site_url: The webside URL.
    """

    site_name: str = "Alliance Auth"
    site_url: str = "https://example.com"


class AllAuth:
    def __init__(self, config: SiteConfig) -> None:

        self._variables: dict[str, Any] = _var_defaults(
            config.site_name, config.site_url
        )
        self._celery_conf: dict[str, Any] = _CELERY_CONF_DEFAULTS
        self._installed_apps: list[str] = []
        self._beat_schedule: dict[str, dict[str, Any]] = {}

    def var(self, *, name: str, value: Any) -> Self:
        """
        Sets a variable to a value.

        :name: The Python identifier for the value.  This should be in
               SCREAMING_SNAKE_CASE if the AA Django app is the intended
               consumer, as Django ignores variables named in another format.
        :value: The value to assign to this variable.
        """
        self._variables[name] = value
        return self

    def vars(self, vars: dict[str, Any]) -> Self:
        """
        Sets a collection of variables' values.

        :vars: Map of (name, value).
        """
        for k, v in vars.items():
            self.var(k, v)
        return self

    def with_plugin(self, plugin: AppPlugin) -> Self:
        """
        Adds a plugin app to install.

        :plugin: An `AppPlugin` config.
        """
        self._installed_apps.append(plugin.module)
        self.vars(plugin.vars)
        if plugin.schedule:
            self._beat_schedule |= plugin.schedule
        return self

    def with_plugins(self, plugins: list[AppPlugin]) -> Self:
        """
        Adds multiple plugin apps to install.

        :plugins: A list of `AppPlugin` configs.
        """
        for p in plugins:
            self.with_plugin(p)
        return self

    def celery_conf(self, *, key: str, value: Any) -> Self:
        """Add a setting in the celery app for AA.

        :key: The conf key name.
        :value: The value.
        """
        self._celery_conf[key] = value
        return self

    def celery_conf_multi(self, *kvs: dict[str, Any], **kwargs: Any) -> Self:
        """Add multiple settings in the celery app for AA."""
        for kv in kvs:
            self._celery_conf.update(kv)
        self._celery_conf.update(kwargs)
        return self

    def install(self, namespace: dict[str, Any]) -> None:
        """
        Add this instance's variables to a module namespace's `__all__` tuple.

        This class exists so that a user's settings module may be set
        dynamically and without having to hardcode secrets.  This gets to that
        runtime by being wildcard imported, so this method populates the list of
        variables that appear in such an import.

        Note that this will exclude all other module namespace members from a
        wildcard import.  Use a named import if needed.

        :namespace: A module namespace to "install" this instance's variables into.
                    Intended to be called with the value `globals()` at the end of
                    the file where this app is configured.
        """
        ns = namespace
        exported: list[str] = []

        exported += _apply_runtime_env(ns)

        ns["INSTALLED_APPS"] = [*ns.get("INSTALLED_APPS", []), *self._installed_apps]
        exported.append("INSTALLED_APPS")

        ns["EXTRA_CELERY_CONF"] = {
            **ns.get("EXTRA_CELERY_CONF", {}),
            **self._celery_conf,
        }
        exported.append("EXTRA_CELERY_CONF")

        if self._beat_schedule:
            ns["CELERYBEAT_SCHEDULE"] = {
                **ns.get("CELERYBEAT_SCHEDULE", {}),
                **self._beat_schedule,
            }
            exported.append("CELERYBEAT_SCHEDULE")

        for k, v in self._variables.items():
            ns[k] = v
            exported.append(k)

        all_ = list(ns.get("__all__", []))
        seen = set(all_)
        for n in exported:
            if n not in seen:
                all_.append(n)
                seen.add(n)
        # Deduplicated and coerced to a list.
        ns["__all__"] = all_
